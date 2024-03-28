package ink.xiaonaoweisuo.grade

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.nio.charset.Charset
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.time.LocalDate
import java.time.LocalTime
import java.time.temporal.ChronoUnit
import java.time.DayOfWeek
import android.app.PendingIntent
import android.content.Intent
import ink.xiaonaoweisuo.grade.MainActivity
//这个函数我是想它用来返回课程时间对应的序数，但是似乎效果不理想
fun getTimePosition(): Int {
    val targetTimes = listOf(
        LocalTime.of(8, 0),
        LocalTime.of(10, 5),
        LocalTime.of(14, 0),
        LocalTime.of(16, 5),
        LocalTime.of(19, 0),
        LocalTime.of(20, 45)
    )

    val currentTime = LocalTime.now()

    for ((index, targetTime) in targetTimes.withIndex()) {
        if (currentTime.isBefore(targetTime)) {
            return index
        }
    }

    return 6 // 如果当前时间在所有给定时间节点之后，返回 5
}
//计算传入的日期，到今天过了多少周余多少天，返回值周
private fun weeksSince(year: Int, mon: Int, day: Int): Int {
    val targetDate = LocalDate.of(year, mon, day)
    val now = LocalDate.now()

    val totalDays = ChronoUnit.DAYS.between(targetDate, now).toInt()
    return totalDays / 7
}
private fun dayOfWeekIndexToday(): Int {
    val today = LocalDate.now()
    val dayOfWeek = today.dayOfWeek
    return when (dayOfWeek) {
        DayOfWeek.MONDAY -> 0
        DayOfWeek.TUESDAY -> 1
        DayOfWeek.WEDNESDAY -> 2
        DayOfWeek.THURSDAY -> 3
        DayOfWeek.FRIDAY -> 4
        DayOfWeek.SATURDAY -> 5
        DayOfWeek.SUNDAY -> 6
    }
}
//读取存储课程表数据的文件
private fun readJsonData(context: Context): Map<String, List<Any>> {
    var map = emptyMap<String, List<Any>>() // 初始化一个空的 map
    try {
        val appFolderPath = context.applicationInfo.dataDir + "/app_flutter/"
        val file = File(appFolderPath, "appwidget.json")
        if (file.exists()) {
            val content = file.readText(Charset.defaultCharset())
            val gson = Gson()
            map = gson.fromJson(content, object : TypeToken<Map<String, List<Any>>>() {}.type)
        }
    } catch (e: Exception) {
        e.printStackTrace()
    }
    return map
}


class WidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
            // // 创建一个启动应用程序的Intent
            // val intent = Intent(context, MainActivity::class.java)
            // // 如果您的应用程序有任何参数需要传递，可以在这里添加额外的信息到Intent中

            // // 创建一个PendingIntent，当用户点击小部件时触发该Intent
            // val pendingIntent = PendingIntent.getActivity(context, 0, intent, 0)

            // // 获取远程视图对象
            // val views = RemoteViews(context.packageName, R.layout.app_widget)

            // // 将PendingIntent关联到小部件的点击事件
            // views.setOnClickPendingIntent(R.id.mainwidget, pendingIntent)
            
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.app_widget)
        val mapdata = readJsonData(context)
        val startdate = mapdata["startdate"] as List
        val year = (startdate[0] as Double).toInt()
        val mon = (startdate[1] as Double).toInt()
        val day = (startdate[2] as Double).toInt()
        val daynum = dayOfWeekIndexToday()//星期几
        val weeknum = weeksSince(year,mon,day)//周数
        val time = getTimePosition()//时间序数
        val schedule = mapdata["schedule"] as List<List<Any>>//读取课表数据
        val weekSchedule = schedule[weeknum] as List<Any>//读取1周课表
        //定位计算公式d=星期几，y=时间序数，positonKey=定位值，positonKey+1=y*7+d
        val Timelist = arrayOf("8:00\n9:35", "10:05\n11:40", "14:00\n15:35", "16:05\n17:40", "19:00\n20:35", "20:45\n22:20")

        if (time != 6) {  // 课上完之前
            val positionKey = time * 7 + daynum

            //val seccourse = weekSchedule[positionKey+1] as Map<String, Any>
            views.setTextViewText(R.id.FirstTime, Timelist[time])
            if(time!=5){
                views.setTextViewText(R.id.SecondTime, Timelist[time+1])
            }else{
                views.setTextViewText(R.id.SecondTime, "52:01\n02:58")
            }
            val finalcourse = weekSchedule[positionKey] as Map<String, Any>
            if (finalcourse["courseName"].toString() != "") {
                views.setTextViewText(
                    R.id.FirstCourseName,
                    finalcourse["courseName"].toString()
                )
                val ps = finalcourse["coursePeriod"].toString()
                val tn = finalcourse["teacherName"].toString()
                views.setTextViewText(R.id.FirstPosition, "$tn | $ps")
            } else {
                views.setTextViewText(R.id.FirstCourseName, "本节无课")
                views.setTextViewText(R.id.FirstPosition, "去做点自己喜欢的事吧")
            }
            if(positionKey!=41) {//周课表的数量是0-41
                val secondcourse = weekSchedule[positionKey+7] as Map<String, Any>
                if (secondcourse["courseName"].toString() != "") {
                    views.setTextViewText(
                        R.id.SecondCourseName,
                        secondcourse["courseName"].toString()
                    )
                    val ps = secondcourse["coursePeriod"].toString()
                    val tn = secondcourse["teacherName"].toString()
                    views.setTextViewText(R.id.SecondPosition, "$tn | $ps")
                } else {
                    views.setTextViewText(R.id.SecondCourseName, "本节无课")
                    views.setTextViewText(R.id.SecondPosition, "去做点自己喜欢的事吧")
                }
            }else{
                views.setTextViewText(R.id.SecondCourseName, "我赌明天是周一")
                views.setTextViewText(R.id.SecondTime, "==\n==")
                views.setTextViewText(R.id.SecondPosition, "赌赢了帮我补作业")
            }
        }else{//全部课上完以后
            views.setTextViewText(R.id.FirstCourseName, "看啥？没课了")
            views.setTextViewText(R.id.FirstTime, "==\n==")
            views.setTextViewText(R.id.FirstPosition, "去做点自己喜欢的事吧")
            views.setTextViewText(R.id.SecondCourseName, "如果你觉得无聊")
            views.setTextViewText(R.id.SecondTime, "==\n==")
            views.setTextViewText(R.id.SecondPosition, "来和我写代码打游戏")
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
