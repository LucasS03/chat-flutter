import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Map<String, dynamic> userRoot;
String idMedico;
String nameMedico;

String idRoot = "ShnNaXOBpx1LjIQZj4nz";

class ChatAdm extends StatefulWidget {

  String id;
  String name;
  ChatAdm(id, name) {
    this.id = id;
    this.name = name;
    idMedico = id;
    nameMedico = name;
  }

  @override
  _ChatAdmState createState() => _ChatAdmState();
}

class _ChatAdmState extends State<ChatAdm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
                child: StreamBuilder(
                    stream: Firestore.instance.collection("messages")
                              .document(widget.id)
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

// ENVIAR MENSAGEM
void _sendMessage(String id, {String text, String imgUrl}) async {
  // id usuario root: ShnNaXOBpx1LjIQZj4nz
  var root = await Firestore.instance.collection("users").document("ShnNaXOBpx1LjIQZj4nz").get();
  userRoot = root.data;

  // messages/idUsuario/messages
  Firestore.instance.collection("messages")
    .document(id)
    .collection("messages")
    .add(
      {
        "text": text,
        "imgUrl": imgUrl,
        "senderName": userRoot["name"],
        "senderPhotoUrl": userRoot["photoUrl"],
        "date": formatDate(DateTime.now(), [dd, '/', mm, '/', yyyy]),
        "hour": formatDate(DateTime.now(), [HH, ':', nn])
      }
    );
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
            // IconButton(
               // icon: Icon(Icons.photo_camera),
               // onPressed: () {},
                // onPressed: () async {
                //   await _ensureLoggedIn();
                //   File imgFile = await ImagePicker.pickImage(source: ImageSource.camera);
                //   if(imgFile == null) return;

                //   StorageUploadTask task = FirebaseStorage.instance.ref()
                //       // .child("photos") // inserir em pasta
                //       .child(googleSignIn.currentUser.id.toString() +
                //               DateTime.now().millisecondsSinceEpoch.toString()
                //       ).putFile(imgFile);

                //   StorageTaskSnapshot taskSnapshot = await task.onComplete;
                //   String url = await taskSnapshot.ref.getDownloadURL();
                //   _sendMessage(imgUrl: url);
                // }
            // ),
         
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration.collapsed(
                  hintText: "Digite sua mensagem...",
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: (text) {
                  // _handleSubmitted(text);
                  // _reset();
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS ?
                CupertinoButton(
                  child: Text("Enviar"),
                  onPressed: _isComposing ? (){
                    _sendMessage(idMedico, text: _textController.text);
                    _reset();
                  } : null
                ) :
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isComposing ? (){
                    _sendMessage(idMedico, text: _textController.text);
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


class ChatMessage extends StatelessWidget {

  final Map<String, dynamic> data;
  ChatMessage(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: data["senderName"] == nameMedico ?
      Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(data["senderPhotoUrl"]),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Color(0xFFA2DFF9)
                ),
                padding: EdgeInsets.all(10.0),
                margin: EdgeInsets.only(right: 55.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data["senderName"],
                      style: Theme.of(context).textTheme.subtitle.merge(
                        TextStyle(color: Colors.white)
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(top: 5.0),
                        child: data["imgUrl"] != null ?
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: Image.network(data["imgUrl"], width: MediaQuery.of(context).size.width/1.4,),
                        ) :
                        Text(data["text"], style: TextStyle(color: Colors.white),)
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        data["date"] + " " + data["hour"],
                        style: Theme.of(context).textTheme.caption.merge(
                                TextStyle(color: Colors.white)
                        ),
                      )
                    ),

                  ],
                ),
              )
            )
          ],
      ) :
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Color(0xFFF6C214),
              ),
              padding: EdgeInsets.all(10.0),
              margin: EdgeInsets.only(left: 80.0, right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data["senderName"],
                    style: Theme.of(context).textTheme.subtitle.merge(
                      TextStyle(color: Colors.white)
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: data["imgUrl"] != null ?
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: Image.network(data["imgUrl"], width: MediaQuery.of(context).size.width/1.4,),
                      ) :
                      Text(
                        data["text"],
                        style: TextStyle(color: Colors.white),
                      )
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      data["date"] + " " + data["hour"],
                      style: Theme.of(context).textTheme.caption.merge(
                                TextStyle(color: Colors.white)
                      ),
                    )
                  ),

                ],
              ),
            )
          ),
        ],
      )
    );
  }
}