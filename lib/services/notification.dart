import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'database.dart';

class Nofication extends StatefulWidget {
  @override
  State<Nofication> createState() => NoficationState();
}

class NoficationState extends State<Nofication> {
  late Future<List<Notifications>> notisql;
  List<Notifications> notifications = [];
  var dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    refreshList();
  }

  Future<void> refreshList() async {
    notisql = dbHelper.getNotifications();
    notisql.then((value) {
      if (value != null) {
        setState(() {
          notifications = value;

          // Sắp xếp theo thời gian, từ mới nhất đến cũ nhất
          notifications.sort((a, b) {
            DateTime dateA = DateFormat('y MMM EEEE d hh:mm a').parse(a.time!);
            DateTime dateB = DateFormat('y MMM EEEE d hh:mm a').parse(b.time!);
            return dateB.compareTo(dateA); // Sắp xếp theo thứ tự giảm dần
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Notifications> todayNotifications = [];
    List<Notifications> olderNotifications = [];
    DateTime now = DateTime.now();

    for (Notifications noti in notifications) {
      DateTime notiTime = DateFormat('y MMM EEEE d hh:mm a').parse(noti.time!);
      if (notiTime.year == now.year && notiTime.month == now.month && notiTime.day == now.day) {
        todayNotifications.add(noti);
      } else {
        olderNotifications.add(noti);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            Text(
              'Thông báo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            IconButton(
              onPressed: () {
                for (Notifications noti in notifications) {
                  dbHelper.delete(noti.no);
                }
                refreshList();
              },
              icon: Icon(
                Ionicons.trash,
                color: Colors.grey[800],
                size: 24,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: refreshList,
        color: Colors.green,
        child: CustomScrollView(
          slivers: [
            if (todayNotifications.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(width: 20,),
                      Text(
                        'Hôm nay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildNotificationItem(todayNotifications[index]),
                  childCount: todayNotifications.length,
                ),
              ),
            ],
            if (olderNotifications.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(width: 20,),
                      Text(
                        'Cũ hơn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildNotificationItem(olderNotifications[index]),
                  childCount: olderNotifications.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Notifications notifi) {
    return Dismissible(
      key: Key(notifi.no.toString()),
      direction: DismissDirection.endToStart,

      background: Container(
        // color: Colors.red,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete,color: Theme.of(context).colorScheme.secondaryContainer,),
      ),
      onDismissed: (direction) async {
        await dbHelper.delete(notifi.no!);
        setState(() {
          notifications.remove(notifi);
        });
      },
      child: Container(
        margin: EdgeInsets.all(1),
        padding: EdgeInsets.all(16),
        // color: Theme.of(context).colorScheme.onPrimaryFixed,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.onPrimaryFixed,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${notifi.id}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8,),
            Text(
              '${notifi.noti}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8,),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('EEE, dd/MM/y hh:mm a').format(
                    DateFormat('y MMM EEEE d hh:mm a').parse(notifi.time!)
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Notifications {
  int? no;
  String? id;
  String? noti;
  String? time;

  Notifications(this.no, this.id, this.noti, this.time);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'no': no,
      'id': id,
      'noti': noti,
      'time': time,
    };
    return map;
  }

  Notifications.fromMap(Map<dynamic, dynamic> map) {
    no = map['no'];
    id = map['id'];
    noti = map['noti'];
    time = map['time'];
  }
}
