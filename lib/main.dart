import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

// final dummySnapshot = [
//  {"name": "Avery", "votes": 10},
//  {"name": "Abraham", "votes": 14},
//  {"name": "Richard", "votes": 11},
//  {"name": "Ike", "votes": 10},
//  {"name": "Justin", "votes": 1},
// ];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}



class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Name Votes'),
        backgroundColor: Color.fromRGBO(46, 204, 113, 1),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _otherPage, //activates otherpage navigator widget
          )
        ],
      ),
      body: _buildBody(context),
    );
  }

  //this is the second route that has the TabBar with the different categories 
  //The data for the dat bars are located below 
  void _otherPage() {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return MaterialApp(
          home: DefaultTabController(
            length: choices.length,
            child: Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  new IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pop(context);
                      print('going home');
                    },
                  )
                ],
                backgroundColor: Color.fromRGBO(46, 204, 113, 1),
                title: const Text('Second PAge'),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: choices.map((Choice choice) {
                    return Tab(
                      text: choice.title,
                      icon: Icon(choice.icon),
                    );
                  }).toList(),
                ),
              ),
              body: TabBarView(
                children: choices.map((Choice choice) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ChoiceCard(choice: choice),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    ));
  }

  Widget _buildBody(BuildContext context) {
    //  get actual snapshot from Cloud Firestore
    //Streambuilder widget listens for updates to the database and refreshes the list whenever the data changes. When there's no data, it shows a progress indicator.
    return StreamBuilder<QuerySnapshot>(
      //Dart Firestore reference thaty calls to the 'baby' collection
      //.snapshots() returns a stream of snapshots of the data
      stream: Firestore.instance.collection('baby').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
          color: Color.fromRGBO(200, 247, 197, .75),
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.votes.toString()),
// //The value of votes is a shared resource, and any time that you update a shared resource (especially when the new value depends on the old value) there is a risk of creating a race condition. Instead, when updating a value in any database, you should use a transaction.// //
          onTap: () => Firestore.instance.runTransaction((transaction) async {
                final freshSnapshot = await transaction.get(record.reference);
                final fresh = Record.fromSnapshot(freshSnapshot);
                print('vote');

                await transaction
                    .update(record.reference, {'votes': fresh.votes + 1});
              }),
          //instead of just printing the record to the console, this new line updates the baby name's database reference by incrementing the vote count by one.
          //  onTap: () => record.reference.updateData({'votes': record.votes + 1}),
          //  onTap: () => print(record),
        ),
      ),
    );
  }
}

class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}


////////////////////////////
////////////////////////////
////////////////////////////
////////////////////////////
////////////////////////////
/// BELOW ARE THE WIDGETS FOR THE SECOND ROUTE tabBar
class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

// the widgets and their icons
const List<Choice> choices = const <Choice>[
  const Choice(title: 'MUSIC', icon: Icons.library_music),
  const Choice(title: 'VIDEOS', icon: Icons.video_library),
  const Choice(title: 'NEWS', icon: Icons.rss_feed),
  const Choice(title: 'PODCASTS', icon: Icons.record_voice_over),
];


//Cards to display the widgets in the body once tehy are selected 
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({Key key, this.choice}) : super(key: key);
  final Choice choice;
  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Card(
      color: Colors.greenAccent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(choice.icon, size: 128.0, color: textStyle.color),
            Text(choice.title, style: textStyle),
          ],
        ),
      ),
    );
  }
}
