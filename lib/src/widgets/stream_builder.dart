import 'dart:async';

import '../core/async_snapshot.dart';
import '../core/async_widget_builder.dart';
import '../core/build_context.dart';
import 'stateful_widget.dart';
import 'widget.dart';

/// A [Widget] that is rebuilt with the latest snapshot of a [Stream].
final class StreamBuilder<T> extends StatefulWidget {
  final AsyncWidgetBuilder<T> builder;
  final Stream<T>? stream;
  final T? initialData;

  /// Creates a new [StreamBuilder].
  const StreamBuilder(
    this.builder, {
    this.stream,
    this.initialData,
    super.key,
    super.ref,
  });

  @override
  State createState() => StreamBuilderState<T, StreamBuilder<T>>();
}

final class StreamBuilderState<T, U extends StreamBuilder<T>> extends State<U> {
  StreamSubscription<T>? _subscription;
  late AsyncSnapshot<T> _snapshot;

  void _subscribe() {
    if (widget.stream != null) {
      _subscription = widget.stream!.listen(
        (final T data) => setState(
          () => _snapshot = AsyncSnapshot.withData(
            connectionState: ConnectionState.active,
            data: data,
          ),
        ),
        onError: (final Object error, final StackTrace stackTrace) => setState(
          () => _snapshot = AsyncSnapshot.withError(
            connectionState: ConnectionState.active,
            error: error,
            stackTrace: stackTrace,
          ),
        ),
        onDone: () => setState(
          () => _snapshot = _snapshot.inConnectionState(ConnectionState.done),
        ),
      );

      _snapshot = _snapshot.inConnectionState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
  }

  @override
  void initialize() {
    super.initialize();

    _snapshot = widget.initialData == null
        ? AsyncSnapshot.nothing()
        : AsyncSnapshot.withData(
            connectionState: ConnectionState.none,
            data: widget.initialData as T,
          );

    _subscribe();
  }

  @override
  void widgetDidUpdate(final U oldWidget) {
    super.widgetDidUpdate(oldWidget);

    if (widget.stream != oldWidget.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _snapshot = _snapshot.inConnectionState(ConnectionState.none);
      }

      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      widget.builder(context, _snapshot);
}