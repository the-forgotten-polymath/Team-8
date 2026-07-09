import Foundation
let dateStr = "2026-07-09T07:58:01.837718"
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
let date1 = formatter.date(from: dateStr)

formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
let date2 = formatter.date(from: dateStr)
print("3 digits: \(String(describing: date1))")
print("6 digits: \(String(describing: date2))")
