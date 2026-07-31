import 'package:equatable/equatable.dart';
import 'package:tiktac_app/features/stopwatch/data/models/stopwatch_entry.dart';

enum StopwatchStatus { initial, running, paused, error }

class StopwatchState extends Equatable {
  final StopwatchStatus status;
  final int elapsedTime;
  final List<StopwatchEntry> entries;
  final List<StopwatchEntry> filteredEntries;
  final String filterQuery;
  final String? errorMessage;
  final bool isLoading;
  final int? startMillis;
  
  const StopwatchState({
    this.status = StopwatchStatus.initial,
    this.elapsedTime = 0,
    this.entries = const [],
    this.filteredEntries = const [],
    this.filterQuery = '',
    this.errorMessage,
    this.isLoading = false,
    this.startMillis,
  });

  List<StopwatchEntry> get activeEntries => 
      filteredEntries.isEmpty && filterQuery.isEmpty ? entries : filteredEntries;

  StopwatchState copyWith({
    StopwatchStatus? status,
    int? elapsedTime,
    List<StopwatchEntry>? entries,
    List<StopwatchEntry>? filteredEntries,
    String? filterQuery,
    String? errorMessage,
    bool? isLoading,
    int? startMillis,
  }) {
    return StopwatchState(
      status: status ?? this.status,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      entries: entries ?? this.entries,
      filteredEntries: filteredEntries ?? this.filteredEntries,
      filterQuery: filterQuery ?? this.filterQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      startMillis: startMillis ?? this.startMillis,
    );
  }

  @override
  List<Object?> get props => [
        status,
        elapsedTime,
        entries,
        filteredEntries,
        filterQuery,
        errorMessage,
        isLoading,
        startMillis,
      ];
}
