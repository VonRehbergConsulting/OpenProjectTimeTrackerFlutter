import 'package:flutter/material.dart';
import 'package:open_project_time_tracker/app/di/inject.dart';
import 'package:open_project_time_tracker/app/ui/bloc/bloc_page.dart';

import 'package:open_project_time_tracker/app/app_router.dart';
import 'package:open_project_time_tracker/modules/task_selection/ui/time_entries_list/time_entries_list_bloc.dart';
import 'package:open_project_time_tracker/modules/task_selection/ui/time_entries_list/widgets/total_time_list_item.dart';
import 'package:open_project_time_tracker/app/ui/widgets/activity_indicator.dart';

import 'widgets/time_entry_list_item.dart';

class TimeEntriesListPage extends EffectBlocPage<TimeEntriesListBloc,
    TimeEntriesListState, TimeEntriesListEffect> with WidgetsBindingObserver {
  @override
  void onCreate(BuildContext context, TimeEntriesListBloc bloc) {
    super.onCreate(context, bloc);
    // TODO: fix memory leak since observer is never removed
    WidgetsBinding.instance.addObserver(this);
    bloc.reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      inject<TimeEntriesListBloc>().reload(showLoading: true);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void onEffect(BuildContext context, TimeEntriesListEffect effect) {
    effect.when(
      error: (message) {
        final snackBar = SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
  }

  @override
  Widget buildState(BuildContext context, TimeEntriesListState state) {
    final Widget body = state.when(
      loading: () => const Center(child: ActivityIndicator()),
      idle: (
        timeEntries,
        workingHours,
        totalDuration,
      ) =>
          RefreshIndicator(
        onRefresh: context.read<TimeEntriesListBloc>().reload,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: ListView.builder(
            itemCount: timeEntries.length + 1,
            itemBuilder: ((context, index) {
              if (index == 0) {
                return TotalTimeListItem(
                  workingHours,
                  totalDuration,
                  (value) {
                    final duration = Duration(
                      hours: value.hour,
                      minutes: value.minute,
                    );
                    context
                        .read<TimeEntriesListBloc>()
                        .updateWorkingHours(duration);
                  },
                );
              }
              final timeEntry = timeEntries[index - 1];
              return TimeEntryListItem(
                  workPackageSubject: timeEntry.workPackageSubject,
                  projectTitle: timeEntry.projectTitle,
                  hours: timeEntry.hours,
                  comment: timeEntry.comment,
                  action: () {
                    context.read<TimeEntriesListBloc>().setTimeEntry(timeEntry);
                  });
            }),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent work'),
        leading: IconButton(
            onPressed: () {
              context.read<TimeEntriesListBloc>().unauthorize();
            },
            icon: const Icon(Icons.exit_to_app_sharp)),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => AppRouter.routeToWorkPackagesList(context),
      ),
    );
  }
}
