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

//这个函数我是想它用来返回课程时间对应的序数，但是似乎效果不理想
private fun checkClassTime(): Int {
    val currentTime = LocalTime.now()
    val classTimes = listOf(
        "08:00" to "09:35",
        "10:05" to "11:40",
        "14:00" to "15:35",
        "16:05" to "17:40",
        "19:00" to "20:35",
        "20:45" to "22:20"
    )
    if (currentTime.isBefore(LocalTime.parse("08:00"))) {
        return 0
    } else if (currentTime.isAfter(LocalTime.parse("22:20"))) {
        return -1
    }
    var classIndex = 1
    for ((start, end) in classTimes) {
        if (currentTime.isAfter(LocalTime.parse(end))) {
            classIndex++
        } else {
            break
        }
    }
    return classIndex
}
//计算传入的日期，到今天过了多少周余多少天，返回值[周，余天数]
private fun weeksAndDaysSince(year: Int, mon: Int, day: Int): IntArray {
    val targetDate = LocalDate.of(year, mon, day)
    val now = LocalDate.now()

    val totalDays = ChronoUnit.DAYS.between(targetDate, now).toInt()
    val weeks = totalDays / 7
    val remainingDays = totalDays % 7

    return intArrayOf(weeks, remainingDays)
}
//读取存储课程表数据的文件
private fun readJsonData(context: Context): Map<String, Any>? {
    var map: Map<String, Any>? = null
    try {
        val appFolderPath = context.applicationInfo.dataDir + "/app_flutter/"
        val file = File(appFolderPath, "appwidget.json")
        if (file.exists()) {
            val content = file.readText(Charset.defaultCharset())
            val gson = Gson()
            map = gson.fromJson(content, object: TypeToken<Map<String, Any>>(){}.type)
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
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.app_widget)
        val mapdata = readJsonData(context)
        //println(mapdata)
        if (mapdata != null) {
            //val startDate = mapdata["startdate"] as IntArray
            val startdateValue = mapdata["startdate"]
            if (startdateValue is ArrayList<*>) {
                if (startdateValue[0] is Double && startdateValue[1] is Double && startdateValue[2] is Double) {
                    val year = (startdateValue[0] as Double).toInt()
                    val month = (startdateValue[1] as Double).toInt()
                    val day = (startdateValue[2] as Double).toInt()
                    val position = weeksAndDaysSince(year, month, day)
                    val schedule = mapdata["schedule"]
                    if (schedule is ArrayList<*>) {
                        val pweek=schedule[position[0]]
                        //val pweek = schedule[8]//周
                        val num = checkClassTime()
                        var firsttime = ""
                        var secondtime = ""

                        if (num == 0) {
                            firsttime = "8:00\n9:35"
                            secondtime = "10:05\n11:40"
                        } else if (num == 1) {
                            firsttime = "8:00\n9:35"
                            secondtime = "10:05\n11:40"
                        } else if (num == 2) {
                            firsttime = "10:05\n11:40"
                            secondtime = "14:00\n15:35"
                        } else if (num == 3) {
                            firsttime = "14:00\n15:35"
                            secondtime = "16:05\n17:40"
                        } else if (num == 4) {
                            firsttime = "16:05\n17:40"
                            secondtime = "19:00\n20:35"
                        } else if (num == 5) {
                            firsttime = "19:00\n20:35"
                            secondtime = "20:45\n22:20"
                        } else {
                            firsttime = "52:01\n02:51"
                            secondtime = "52:01\n02:51"
                        }
                        //设定时间
                        views.setTextViewText(R.id.FirstTime, num.toString())
                        views.setTextViewText(R.id.SecondTime, secondtime)
                        if (pweek is ArrayList<*>) {
                            if (num != -1) {
                                if (num != 5) {
                                    val section = position[1]+7*num
                                    val psec1=pweek[section]
                                    val psec2=pweek[section+7]
                                    if (psec1 is Map<*, *>) {
                                        val courseName = psec1["courseName"]
                                        val tec=psec1["teacherName"]
                                        val room = psec1["coursePeriod"]
                                        val posi = "$tec | $room"
                                        if (courseName is CharSequence) {
                                            views.setTextViewText(R.id.FirstCourseName, courseName)
                                            views.setTextViewText(R.id.FirstPosition, posi)
                                        }
                                    }
                                    if (psec2 is Map<*, *>) {
                                        val courseName = psec2["courseName"]
                                        val room = psec2["coursePeriod"]
                                        val tec=psec2["teacherName"]
                                        val posi = "$tec  $room"
                                        if (courseName is CharSequence) {
                                            views.setTextViewText(R.id.SecondCourseName, courseName)
                                            views.setTextViewText(R.id.SecondPosition, posi)
                                        }
                                    }
                                } else {
                                    val section = position[1]+7*num
                                    val psec1=pweek[section]
                                    if (psec1 is Map<*, *>) {
                                        val courseName = psec1["courseName"]
                                        if (courseName is CharSequence) {
                                            views.setTextViewText(R.id.FirstCourseName, courseName)
                                        }
                                    }
                                    views.setTextViewText(R.id.SecondCourseName, "今天课上完咯")
                                }
                            } else {
                                views.setTextViewText(R.id.FirstCourseName, "今天课上完咯")
                                views.setTextViewText(R.id.SecondCourseName, "今天课上完咯")
                            }

                        }

                        //views.setTextViewText(R.id.FirstCourseName, pweek[0]::class.simpleName)
                    }
                    //views.setTextViewText(R.id.FirstCourseName, schedule[position[0]][position[1]])
                }
            }
        }
        //views.setTextViewText(R.id.FirstTime, "新的课程时间")
        //views.setTextViewText(R.id.FirstPosition, "新的教师名称 | 新的上课地点")
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
