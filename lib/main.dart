import 'package:chat/chatMedico.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:date_format/date_format.dart';
import 'dart:io';

// Autenticação
final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;

  if(user != null)
    user = await googleSignIn.signInSilently();

  if(user == null)
    user = await googleSignIn.signIn();

  if(await auth.currentUser() == null){
    GoogleSignInAuthentication credentials = await googleSignIn.currentUser.authentication;
    
    await auth.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken
    );
  }

  if(googleSignIn.currentUser != null){
    Firestore.instance.collection("users").document(googleSignIn.currentUser.id).setData(
      {
        "id": googleSignIn.currentUser.id,
        "name": googleSignIn.currentUser.displayName,
        "email": googleSignIn.currentUser.email,
        "photoUrl": googleSignIn.currentUser.photoUrl
      }
    );
  }
}

void main() async {
  await _ensureLoggedIn();
  runApp(Home());
}

// enviar mensagem
_handleSubmitted(String text) async {
  await _ensureLoggedIn();
  _sendMessage(text:text);
}

void _sendMessage({String text, String imgUrl}) {
  // messages/idUsuario/messages
  Firestore.instance.collection("messages").document(googleSignIn.currentUser.id).setData(
    {
      "id": googleSignIn.currentUser.id,
      "name": googleSignIn.currentUser.displayName,
      "photo": googleSignIn.currentUser.photoUrl
    }
  );

  Firestore.instance.collection("messages").document(googleSignIn.currentUser.id).collection("messages").add(
    {
      "text": text,
      "imgUrl": imgUrl,
      "senderName": googleSignIn.currentUser.displayName,
      "senderPhotoUrl": googleSignIn.currentUser.photoUrl,
      "date": formatDate(DateTime.now(), [dd, '/', mm, '/', yyyy]),
      "hour": formatDate(DateTime.now(), [HH, ':', nn])
    }
  );
}

// INICIO
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat App",
      home: Chat(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// CORPO DO CHAT
class Chat extends StatefulWidget {
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat App"),
          centerTitle: true,
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            FlatButton(
              child: Text("MODO ADM", style: TextStyle(color:Colors.white)),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (BuildContext context) => ChatAdministrador()
                  )
                );
              },
            )
          ],
        ),

        body: Column(
          children: <Widget>[
            Expanded(
                child: StreamBuilder(
                    stream: Firestore.instance.collection("messages")
                              .document(googleSignIn.currentUser.id)
                              .collection("messages").snapshots(),
                    builder: (context, snapshot) {
                      switch(snapshot.connectionState){
                        case ConnectionState.none:
                        case ConnectionState.waiting:
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        default:
                          return ListView.builder(
                              reverse: true, // msgs mais novas em baixo
                              itemCount: snapshot.data.documents.length,
                              itemBuilder: (context, index) {
                                List r = snapshot.data.documents.reversed.toList();
                                return ChatMessage(r[index].data);
                              }
                          );
                      }
                    }
                ),
            ),
            Divider(height: 1.0,),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor
              ),
              child: TextComposed(),
            )
          ],
        ),
      ),
    );
  }
}

// BARRA DE TEXTO
class TextComposed extends StatefulWidget {
  @override
  _TextComposedState createState() => _TextComposedState();
}

class _TextComposedState extends State<TextComposed> {

  bool _isComposing = false;
  final _textController = TextEditingController();

  void _reset() {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: Theme.of(context).platform == TargetPlatform.iOS ?
          BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]))
          ) :
          null,
        child: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () async {
                  await _ensureLoggedIn();
                  File imgFile = await ImagePicker.pickImage(source: ImageSource.camera);
                  if(imgFile == null) return;

                  StorageUploadTask task = FirebaseStorage.instance.ref()
                      // .child("photos") // inserir em pasta
                      .child(googleSignIn.currentUser.id.toString() +
                              DateTime.now().millisecondsSinceEpoch.toString()
                      ).putFile(imgFile);

                  StorageTaskSnapshot taskSnapshot = await task.onComplete;
                  String url = await taskSnapshot.ref.getDownloadURL();
                  _sendMessage(imgUrl: url);
                }
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration.collapsed(
                  hintText: "Digite aqui...",
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: (text) {
                  _handleSubmitted(text);
                  _reset();
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS ?
                    CupertinoButton(
                      child: Text("Enviar"),
                      onPressed: _isComposing ? (){
                        _handleSubmitted(_textController.text);
                        _reset();
                      } : null
                    ) :
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isComposing ? (){
                        _handleSubmitted(_textController.text);
                        _reset();
                      } : null
                    )
            )
          ],
        ),
      ),
    );
  }
}

// CONSTROI MENSAGEM
class ChatMessage extends StatelessWidget {

  final Map<String, dynamic> data;
  ChatMessage(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child:  Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(data["senderPhotoUrl"]),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.green[100],
                ),
                padding: EdgeInsets.all(10.0),
                margin: EdgeInsets.only(right: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data["senderName"],
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                    Container(
                        margin: const EdgeInsets.only(top: 5.0),
                        child: data["imgUrl"] != null ?
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: Image.network(data["imgUrl"], width: MediaQuery.of(context).size.width/1.4,),
                        ) :
                        Text(data["text"])
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        data["date"] + " " + data["hour"],
                        style: Theme.of(context).textTheme.caption,
                      )
                    ),

                  ],
                ),
              )
            )
          ],
        )
    );
  }
}

// CONVERSAS ADMINISTRADOR
class ChatAdministrador extends StatefulWidget {
  @override
  _ChatAdministradorState createState() => _ChatAdministradorState();
}

class _ChatAdministradorState extends State<ChatAdministrador> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversas"),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.grey[100],
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection("messages").orderBy("lastDate", descending: true).snapshots(),
          builder: (context, snapshot) {
            switch(snapshot.connectionState){
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Center(
                  child: CircularProgressIndicator(),
                );
              default:
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    // List r = snapshot.data.documents.reversed.toList();
                    return GestureDetector(
                      onTap: () {
                        print("Conversa de ${snapshot.data.documents[index]["name"]}");
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (BuildContext context) => 
                            ChatAdm(
                              snapshot.data.documents[index]["id"],
                              snapshot.data.documents[index]["name"]
                            )
                          )
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  maxRadius: 30,
                                  backgroundImage: NetworkImage(
                                    snapshot.data.documents[index]["photo"]
                                  ),
                                ),

                                SizedBox(width: 10),

                                Text(snapshot.data.documents[index]["name"], style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),

                          Divider()
                        ],
                      ),
                    );
                  }
                );
            }
          }
        ),
      ),
    );
  }
}