import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/models/task.dart';
import 'package:todo/services/notification_services.dart';
import 'package:todo/services/theme_services.dart';
import 'package:todo/ui/pages/add_task_page.dart';
import 'package:todo/ui/size_config.dart';
import 'package:todo/ui/widgets/button.dart';
import 'package:todo/ui/widgets/task_tile.dart';

import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  final TaskController _taskController = Get.put(TaskController());
  late NotifyHelper notifyHelper;
  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();
    notifyHelper.wasApplicationLaunchedFromNotification();
    _taskController.getTasks();
  }

  bool isExtended = false;
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: context.theme.backgroundColor,
      appBar: _appBar(),
      body: Column(
        children: [
          _addTaskBar(),
          _addDateBar(),
          const SizedBox(
            height: 10,
          ),
          _showTasks(),
          Padding(
            padding: const EdgeInsets.only(bottom: 5, top: 3),
            child: Align(
              alignment: const Alignment(0.95, -0.9),
              child: FloatingActionButton.extended(
                foregroundColor: darkGreyClr,
                backgroundColor: primaryClr.withOpacity(.8),
                onPressed: () {
                  if (isExtended) {
                    Get.dialog(AlertDialog(
                      title: const Text('Delete All Tasks'),
                      titleTextStyle: titleStyle,
                      contentTextStyle: subTitleStyle,
                      content: const Text(
                          'Are you sure you want to delete all of your tasks?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isExtended = !isExtended;
                            });
                            Get.back();
                          },
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            notifyHelper.cancelAllNotification();
                            _taskController.deleteAllTasks();
                            setState(() {
                              isExtended = !isExtended;
                            });
                            Get.back();
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ));
                  } else {
                    setState(() {
                      isExtended = !isExtended;
                    });
                  }
                },
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 650),
                  switchInCurve: Curves.bounceIn,
                  switchOutCurve: Curves.bounceOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) =>
                          FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      child: child,
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                    ),
                  ),
                  child: isExtended
                      ? Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.black,
                              ),
                            ),
                            Text("Delete All Tasks")
                          ],
                        )
                      : const Icon(
                          Icons.delete_forever_outlined,
                          color: darkGreyClr,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          ThemeServices().switchTheme();
        },
        icon: Icon(
          Get.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_round_outlined,
          size: 24,
          color: Get.isDarkMode ? Colors.white : darkGreyClr,
        ),
        color: primaryClr,
      ),
      elevation: 0,
      backgroundColor: context.theme.backgroundColor,
      actions: const [
        SizedBox(width: 20),
      ],
    );
  }

  _addTaskBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: subHeadingStyle,
              ),
              Text(
                'Today',
                style: headingStyle,
              )
            ],
          ),
          MyButton(
            label: '+ Add Task',
            onTap: () async {
              await Get.to(() => const AddTaskPage());
              _taskController.getTasks();
            },
          ),
        ],
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 6, left: 20),
      child: DatePicker(
        DateTime.now(),
        width: 70,
        height: 100,
        initialSelectedDate: DateTime.now(),
        selectedTextColor: Colors.white,
        selectionColor: primaryClr,
        dateTextStyle: GoogleFonts.aBeeZee(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        dayTextStyle: GoogleFonts.aBeeZee(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        monthTextStyle: GoogleFonts.aBeeZee(
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        onDateChange: (newDate) {
          setState(() {
            _selectedDate = newDate;
          });
        },
      ),
    );
  }

  _showTasks() {
    return Expanded(child: Obx(() {
      if (_taskController.taskList.isEmpty) {
        return _noTaskMsg();
      } else {
        return ListView.builder(
          scrollDirection: SizeConfig.orientation == Orientation.landscape
              ? Axis.horizontal
              : Axis.vertical,
          itemBuilder: (BuildContext context, int index) {
            var task = _taskController.taskList[index];
            var weekDay = DateFormat('EEEE').format(_selectedDate);
            int taskYear = int.parse(task.date!.split('/')[2]);
            int taskMonth = int.parse(task.date!.split('/')[0]);
            int taskDay = int.parse(task.date!.split('/')[1]);
            if (task.repeat == 'Daily' ||
                (task.repeat == 'Weekly' &&
                    weekDay ==
                        DateFormat('EEEE')
                            .format(DateTime(taskYear, taskMonth, taskDay))) ||
                (task.repeat == 'Monthly' &&
                    task.date!.split('/')[1] ==
                        DateFormat.d().format(_selectedDate)) ||
                task.date == DateFormat.yMd().format(_selectedDate)) {
              var date = DateFormat.jm().parse(task.startTime!);
              var myTime = DateFormat('HH:mm').format(date);

              notifyHelper.scheduledNotification(
                int.parse(myTime.toString().split(':')[0]),
                int.parse(myTime.toString().split(':')[1]),
                task,
              );
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 1300),
                child: SlideAnimation(
                  horizontalOffset: 300,
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () => _showBottomSheet(context, task),
                      child: TaskTile(task),
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
          itemCount: _taskController.taskList.length,
        );
      }
    }));
  }

  _noTaskMsg() {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(seconds: 2),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              direction: SizeConfig.orientation == Orientation.landscape
                  ? Axis.horizontal
                  : Axis.vertical,
              children: [
                SizeConfig.orientation == Orientation.landscape
                    ? const SizedBox(
                        height: 6,
                      )
                    : const SizedBox(height: 220),
                SvgPicture.asset(
                  'images/task.svg',
                  color: primaryClr.withOpacity(0.5),
                  height: 90,
                  semanticsLabel: 'Task',
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Text(
                    "You do not have any tasks yet!\nAdd new tasks to make your days productive",
                    style: subTitleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizeConfig.orientation == Orientation.landscape
                    ? const SizedBox(
                        height: 120,
                      )
                    : const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 4),
          width: SizeConfig.screenWidth,
          height: (SizeConfig.orientation == Orientation.landscape)
              ? (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.6
                  : SizeConfig.screenHeight * 0.8)
              : (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.32
                  : SizeConfig.screenHeight * 0.42),
          color: Get.isDarkMode
              ? darkHeaderClr.withOpacity(.9)
              : Colors.white.withOpacity(.9),
          child: Column(
            children: [
              Flexible(
                child: Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              task.isCompleted == 1
                  ? Container()
                  : _buildBottomSheet(
                      label: 'Task Completed',
                      onTap: () {
                        _taskController.markTaskAsCompleted(task.id!);
                        notifyHelper.cancelNotification(task);
                        Get.back();
                      },
                      clr: primaryClr),
              _buildBottomSheet(
                  label: 'Delete Task',
                  onTap: () {
                    _taskController.deleteTasks(task);
                    notifyHelper.cancelNotification(task);
                    Get.back();
                  },
                  clr: Colors.red[300]!),
              Divider(
                color: Get.isDarkMode ? Colors.grey : darkGreyClr,
              ),
              _buildBottomSheet(
                  label: 'Cancel',
                  onTap: () {
                    Get.back();
                  },
                  clr: primaryClr),
              const SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }

  _buildBottomSheet(
      {required String label,
      required Function() onTap,
      required Color clr,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        height: 65,
        width: SizeConfig.screenWidth * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(
            label,
            style: isClose
                ? titleStyle
                : titleStyle.copyWith(
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
