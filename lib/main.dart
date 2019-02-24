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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Name Votes'),
        backgroundColor: Color.fromRGBO(46, 204, 113, 1),
      ),
      body: _buildBody(context),
    );
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
