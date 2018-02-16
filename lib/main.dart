import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:intl/intl.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new MyHomePage(title: 'Image slide on scroll demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _controller = new ScrollController();

  /// Helper function to generate a bunch of calendar-like list items.
  Iterable<Widget> _generateListItems(DateTime from, DateTime to) sync* {
    DateTime monday = from.add(new Duration(days: 1 + 7 - from.weekday));
    DateTime previous = from;
    while (monday.isBefore(to)) {
      yield new WeekHeaderTile(monday: monday);
      monday = monday.add(const Duration(days: 7));
      if (previous.month != monday.month) {
        yield new MonthHeaderTile(
          date: monday,
          controller: _controller,
        );
      }
      previous = monday;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView(
        controller: _controller,
        children: _generateListItems(DateTime.parse('2018-01-05T00:00:00'),
                DateTime.parse('2020-01-05T00:00:00'))
            .toList(growable: false),
      ),
    );
  }
}

/// This is a stateful widget which listens to scroll notifications
/// and adjusts vertical offset of the backgound image.
///
/// All the logic is in [_MonthHeaderTileState].
class MonthHeaderTile extends StatefulWidget {
  MonthHeaderTile({Key key, @required this.date, this.controller})
      : super(key: key);
  final DateTime date;
  final ScrollController controller;

  @override
  _MonthHeaderTileState createState() => new _MonthHeaderTileState();
}

class _MonthHeaderTileState extends State<MonthHeaderTile> {
  /// Useful to tweak how fast background image slides when scrolling.
  static const double speedCoefficient = 0.5;

  /// Scroll offset at the moment this widget appeared on the screen
  double initOffset;

  /// Size of the viewport, in this case it's the height of parent ListView.
  double viewportSize;

  /// Offset of background image in percents, must be in range [-100.0, 100.0].
  ///
  /// Offset `0.0` means the images is vertically centered, `-100.0` means
  /// it's top-alligned and `100.0` it's bottom-aligned.
  double imageOffset = 0.0;

  /// Called for each scroll notification event.
  void _handleScroll() {
    /// Note that this logic is not bulletproof and might need some tweaking.
    /// But hopefully it is good enough to represent the approach.

    /// We first get the delta of current scroll offset to our [initOffset].
    /// This value would normally be less than the [viewportSize].
    /// It can be positive or negative depending on the direction of scroll.
    final double delta = widget.controller.offset - initOffset;

    /// Having [delta] we can calculate the distance travelled as a percentage
    /// of the [viewportSize].
    final int viewportFraction =
        (100 * delta / viewportSize).round().clamp(-100, 100);

    /// Adjust the value by our [speedCoefficient].
    /// We also negate the result here because the image must actually slide
    /// in the oposite direction to scroll.
    final double offset = -1 * speedCoefficient * viewportFraction;

    if (offset != imageOffset) {
      /// Not every scroll notification will result in a different offset so
      /// we can save on repainting a little.
      setState(() {
        imageOffset = offset;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initOffset = widget.controller.offset;
    print('Init offset for $text is $initOffset');
    viewportSize = widget.controller.position.viewportDimension;
    widget.controller.addListener(_handleScroll);
  }

  // TODO: Also need a didUpdateWidget override to check for new controller

  @override
  void dispose() {
    widget.controller?.removeListener(_handleScroll);
    super.dispose();
  }

  String get text {
    final fmt = new DateFormat.MMMM();
    return fmt.format(widget.date);
  }

  String get imagePath => 'images/month_${widget.date.month}.jpg';

  @override
  Widget build(BuildContext context) {
    /// Adjust standard [Alignment.center] by the value of [imageOffset].
    double y = imageOffset / 100;
    var alignment = Alignment.center.add(new Alignment(0.0, y));
    final theme = Theme.of(context);
    final style = theme.textTheme.title;
    return new RepaintBoundary(
      child: new Container(
        decoration: new BoxDecoration(
          color: Colors.black12,
          image: new DecorationImage(
            alignment: alignment, // Set alignment on the decoration image
            image: new ExactAssetImage(imagePath),
            fit: BoxFit.fitWidth,
          ),
        ),
        constraints: new BoxConstraints(minHeight: 160.0),
        child: new Text(text, style: style),
        padding: const EdgeInsets.fromLTRB(72.0, 17.0, 0.0, 17.0),
      ),
    );
  }
}

class WeekHeaderTile extends StatelessWidget {
  WeekHeaderTile({Key key, @required this.monday})
      : text = _formatText(monday),
        super(key: key);
  final DateTime monday;
  final String text;

  static String _formatText(DateTime monday) {
    final monFmt = new DateFormat.MMMMd();
    final sunday = monday.add(const Duration(days: 6));
    final sunFmt = (sunday.month == monday.month) ? new DateFormat.d() : monFmt;
    return monFmt.format(monday) + ' – ' + sunFmt.format(sunday);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.subhead.copyWith(color: Colors.black54);
    return new Container(
      constraints: new BoxConstraints(minHeight: 48.0),
      child: new Text(text, style: style),
      padding: const EdgeInsets.fromLTRB(72.0, 17.0, 0.0, 17.0),
    );
  }
}
