import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:edu_ws2026_ma204_pm/common.dart';
import 'package:edu_ws2026_ma204_pm/service/Storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ВАЖНО: assets/audios ішіндегі нақты файл аттарын жаз
const musicFile = 'audios/background.mp3';
const moveFile = 'audios/move.mp3';
const buyFile = 'audios/buy.mp3';
const sellFile = 'audios/sell.mp3';

// hex өлшемдері: ені, биіктігі, қатар қадамы
const w = 56.0, h = 64.7, rs = 48.5;

const hints = {
  'Easy':
      '1. Changan > Dunhuang: Buy Silk*3\n'
      '2. Dunhuang > Samarkand: Sell Silk*3\n'
      '3. Samarkand > Dunhuang: Buy Tea*4\n'
      '4. Dunhuang > Samarkand: Sell Tea*4\n'
      '5. Samarkand > Dunhuang: Buy Silk*1, Tea*1, Porcelain*3\n'
      '6. Dunhuang > Constantinople: Sell Porcelain*3\n'
      '7. Constantinople > Roma',
  'Hard':
      '1. Changan > Dunhuang: Buy Silk*1, Tea*1\n'
      '2. Dunhuang > Samarkand: Sell Silk*1, Tea*1\n'
      '3. Samarkand > Dunhuang: Buy Silk*1, Tea*1, Porcelain*1\n'
      '4. Dunhuang > Roma',
};

class GamePage extends StatefulWidget {
  final bool newGame;
  final String? level;
  GamePage({this.newGame = true, this.level});
  @override
  State<GamePage> createState() => _GameState();
}

class _GameState extends State<GamePage> {
  List mapData = [], trades = [], diffs = [], target = [], txs = [], hist = [];
  Map items = {}, goods = {};
  String diff = 'Easy';
  int coins = 0, days = 0, startDays = 0;
  int r = 5, c = 11; // r = қатар (Y), c = баған (X). Changan = 11,5
  bool ready = false, over = false;
  final bgm = AudioPlayer(), sfx = AudioPlayer();

  // ---------- дыбыс ----------
  void play(AudioPlayer p, String file, double vol) async {
    try {
      await p.play(AssetSource(file), volume: vol);
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    load();
    bgm.setReleaseMode(ReleaseMode.loop);
    play(bgm, musicFile, Storage.music);
  }

  @override
  void dispose() {
    bgm.dispose();
    sfx.dispose();
    super.dispose();
  }

  // ---------- 1. жүктеу ----------
  load() async {
    mapData = jsonDecode(await rootBundle.loadString('assets/data/map.json'));
    trades = jsonDecode(await rootBundle.loadString('assets/data/trades.json'));
    diffs = jsonDecode(
      await rootBundle.loadString('assets/data/difficulties.json'),
    );
    for (var m in mapData) {
      items['${m['positionX']},${m['positionY']}'] = m;
    }

    var g = widget.newGame ? null : Storage.game;
    if (g == null) {
      // жаңа ойын
      diff = widget.level ?? Storage.difficulty;
      var d = diffs.firstWhere((e) => e['difficulty'] == diff);
      coins = d['coins'];
      days = d['days'];
      startDays = days;
      target = d['targets'];
    } else {
      // Continue
      diff = g['diff'];
      target = g['target'];
      startDays = g['startDays'];
      hist = g['hist'];
      apply(jsonDecode(g['snap']));
    }
    save();
    setState(() => ready = true);
  }

  // ---------- 2. сақтау ----------
  String snap() => jsonEncode({
    'coins': coins,
    'days': days,
    'r': r,
    'c': c,
    'goods': goods,
    'txs': txs,
  });

  void apply(Map m) {
    coins = m['coins'];
    days = m['days'];
    r = m['r'];
    c = m['c'];
    goods = m['goods'];
    txs = m['txs'];
  }

  void save() => Storage.saveGame({
    'diff': diff,
    'target': target,
    'startDays': startDays,
    'hist': hist,
    'snap': snap(),
  });

  // ---------- 3. жүріс ----------
  // көрші 6 тор: [қатар өзгерісі, баған өзгерісі]
  List<List<int>> near() {
    var d = r.isOdd
        ? [
            [0, -1],
            [0, 1],
            [-1, 0],
            [-1, 1],
            [1, 0],
            [1, 1],
          ]
        : [
            [0, -1],
            [0, 1],
            [-1, -1],
            [-1, 0],
            [1, -1],
            [1, 0],
          ];
    return d
        .map((e) => [r + e[0], c + e[1]])
        .where((p) => p[0] >= 0 && p[0] < 8 && p[1] >= 0 && p[1] < 12)
        .toList();
  }

  void move(int rr, int cc) {
    if (over) return;

    // ағымдағы қаланы басса, сауда қайта ашылады
    if (rr == r && cc == c) {
      trade();
      return;
    }
    if (days <= 0) return;
    if (!near().any((p) => p[0] == rr && p[1] == cc)) return;

    // Hard: тау мен теңізге жүруге болмайды
    var type = items['$cc,$rr']?['type'];
    if (diff == 'Hard' && (type == 'mountain' || type == 'sea')) return;

    hist.add(snap()); // undo үшін алдыңғы күйді сақтау
    setState(() {
      r = rr;
      c = cc;
      days--;
    });
    play(sfx, moveFile, Storage.sfx);
    save();

    var city = items['$c,$r'];
    if (city?['name'] == 'Roma') {
      finish(target.every((t) => (goods[t['name']] ?? 0) >= t['quantity']));
    } else if (days == 0) {
      finish(false);
    } else if (city?['type'] == 'city') {
      trade();
    }
  }

  void undo() {
    if (over || hist.isEmpty) return;
    setState(() => apply(jsonDecode(hist.removeLast())));
    save();
  }

  // ---------- 4. сауда ----------
  void trade() {
    var city = items['$c,$r']?['name'];
    var found = trades.where((e) => e['city'] == city);
    if (found.isEmpty || over) return;
    var tr = found.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, refresh) {
          // buy = true: ойыншы сатып алады
          Widget row(Map g, bool buy) {
            return ListTile(
              leading: goodIcon(g['name']),
              title: Text('${g['name']}  ${g['price']}'),
              trailing: ElevatedButton(
                child: Text(buy ? 'Buy' : 'Sell'),
                onPressed: () {
                  String n = g['name'];
                  int p = g['price'];
                  if (buy) {
                    if (coins < p) return;
                    coins -= p;
                    goods[n] = (goods[n] ?? 0) + 1;
                  } else {
                    if ((goods[n] ?? 0) < 1) return;
                    coins += p;
                    goods[n] -= 1;
                  }
                  txs.add({
                    'city': city,
                    (buy ? 'bought' : 'sold'): {n: 1},
                  });
                  play(sfx, buy ? buyFile : sellFile, Storage.sfx);
                  save();
                  refresh(() {}); // диалогты жаңарту
                  setState(() {}); // негізгі экранды жаңарту
                },
              ),
            );
          }

          return AlertDialog(
            title: Text('$city   🪙$coins'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...tr['city_selling'].map<Widget>((g) => row(g, true)),
                    Text('Sell', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...tr['city_buying'].map<Widget>((g) => row(g, false)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- 5. жеңіс / жеңіліс ----------
  void finish(bool win) {
    over = true;
    Storage.addRecord({
      'difficulty': diff,
      'success': win,
      'time': DateTime.now().toString().substring(0, 16),
      'days': startDays - days,
      'coins': coins,
      'txs': txs,
      'goods': goods,
    });
    Storage.saveGame(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          win
              ? 'You have completed the mission!'
              : 'You failed to finish the mission...',
        ),
        actions: [
          if (win && diff != 'Hard')
            TextButton(
              onPressed: () => again('Hard'),
              child: Text('Next Level'),
            ),
          if (win)
            TextButton(
              onPressed: () => Navigator.popUntil(context, (x) => x.isFirst),
              child: Text('Return to Main Menu'),
            ),
          if (!win)
            TextButton(onPressed: () => again(diff), child: Text('Retry')),
          if (!win && diff != 'Easy')
            TextButton(
              onPressed: () => again('Easy'),
              child: Text('Lower Difficulty'),
            ),
        ],
      ),
    );
  }

  void again(String level) {
    Navigator.pop(context); // диалогты жабу
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GamePage(level: level)),
    );
  }

  // ---------- UI ----------
  Widget goodItem(String n, int q) => Padding(
    padding: EdgeInsets.all(4),
    child: Column(
      children: [
        goodIcon(n),
        Text('$n x$q', style: TextStyle(fontSize: 11)),
      ],
    ),
  );

  Widget box(String title, List<Widget> kids) => Card(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(children: kids),
        ],
      ),
    ),
  );

  // бір hex тор
  Widget cell(int rr, int cc) {
    var it = items['$cc,$rr'];
    String type = it?['type'] ?? 'plain';
    if (type == 'city') type = 'plain'; // қала астында жазық
    bool hi = near().any((p) => p[0] == rr && p[1] == cc);

    return Positioned(
      left: cc * w + (rr.isOdd ? w / 2 : 0),
      top: rr * rs,
      child: GestureDetector(
        onTap: () => move(rr, cc),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/scenes/hexagonal_$type.png',
                fit: BoxFit.fill,
                color: hi ? Colors.green.withOpacity(0.5) : null, // жасыл белгі
                colorBlendMode: BlendMode.srcATop,
              ),
              if (it?['type'] == 'city')
                Image.asset('assets/cities/${it['name'].toLowerCase()}.png'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ready)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Color(0xFFFFF3C4),
      body: SafeArea(
        child: Column(
          children: [
            // жоғарғы панель
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Image.asset('assets/scenes/logo.png', height: 48),
                IconButton(icon: Icon(Icons.undo), onPressed: undo),
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Hint ($diff)'),
                      content: Text(hints[diff]!),
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '$diff   🪙 $coins   📅 $days   ',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  // сол жақ: goods тізімдері
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        box(
                          'Current Goods',
                          goods.entries
                              .where((e) => e.value > 0)
                              .map<Widget>((e) => goodItem(e.key, e.value))
                              .toList(),
                        ),
                        box(
                          'Target Goods',
                          target
                              .map<Widget>(
                                (t) => goodItem(t['name'], t['quantity']),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  // карта
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: 12 * w + w / 2,
                          height: 7 * rs + h,
                          child: Stack(
                            children: [
                              for (var rr = 0; rr < 8; rr++)
                                for (var cc = 0; cc < 12; cc++) cell(rr, cc),
                              // қала аттары
                              for (var m in mapData)
                                if (m['type'] == 'city')
                                  Positioned(
                                    left:
                                        m['positionX'] * w +
                                        (m['positionY'].isOdd ? w / 2 : 0),
                                    top: m['positionY'] * rs - 6,
                                    child: IgnorePointer(
                                      child: Container(
                                        color: Colors.white70,
                                        child: Text(
                                          m['name'],
                                          style: TextStyle(fontSize: 8),
                                        ),
                                      ),
                                    ),
                                  ),
                              // ойыншы (анимациямен жылжиды)
                              AnimatedPositioned(
                                duration: Duration(milliseconds: 300),
                                left: c * w + (r.isOdd ? w / 2 : 0) + 12,
                                top: r * rs + 14,
                                child: IgnorePointer(
                                  child: Icon(
                                    Icons.person_pin_circle,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
