import 'package:edu_ws2026_ma204_pm/common.dart';
import 'package:edu_ws2026_ma204_pm/service/Storage_service.dart';
import 'package:flutter/material.dart';
// import 'common.dart';
// import 'storage.dart';

class RecordsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var list = Storage.records;
    return Scaffold(
      appBar: AppBar(title: Text('Game Records')),
      body: bgBox(
        list.isEmpty
            ? Center(
                child: Text(
                  'No records yet. Play a game first!',
                  style: TextStyle(fontSize: 20),
                ),
              )
            : Center(
                child: SizedBox(
                  width: 500,
                  child: ListView(
                    children: [
                      for (var rec in list)
                        Card(
                          child: ListTile(
                            title: Text(rec['difficulty']),
                            subtitle: Text(rec['time']),
                            trailing: Text(
                              rec['success'] ? 'Succeed' : 'Failed',
                              style: TextStyle(
                                color: rec['success']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(rec),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map r;
  DetailPage(this.r);

  Widget goodsRow(Map? m) => Wrap(
    children: (m ?? {}).entries
        .where((e) => e.value > 0)
        .map<Widget>(
          (e) => Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              children: [goodIcon(e.key), Text('${e.key} x${e.value}')],
            ),
          ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Detail')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Used days: ${r['days']}', style: TextStyle(fontSize: 18)),
          Text('Coins: ${r['coins']}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 12),
          Text(
            'Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (var t in r['txs'])
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['city'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Sold:'),
                    goodsRow(t['sold']),
                    Text('Purchased:'),
                    goodsRow(t['bought']),
                  ],
                ),
              ),
            ),
          SizedBox(height: 12),
          Text(
            'Final goods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          goodsRow(r['goods']),
        ],
      ),
    );
  }
}
