import re

with open("RSMS_Project/Views/AppointmentManagementView.swift", "r") as f:
    code = f.read()

# 1. Remove the computed vars for appointments and standardTasks
code = re.sub(r'var appointments: \[Appointment\] \{[\s\S]*?\}\n', '', code)
code = re.sub(r'var standardTasks: \[Appointment\] \{[\s\S]*?\}\n', '', code)

# 2. Replace standardTasks usages in UI with filteredAppointments
code = code.replace("standardTasks", "filteredAppointments")

# 3. Fix filteredAppointments logic
code = code.replace("appointment.title.lowercased().contains(q)", "false")
code = code.replace("appointment.assignedTo", "appointment.salesAssociateId")

# 4. Fix Appointment creation
code = code.replace("title: taskTitle,", "")
code = code.replace("taskTitle", "description") # Reusing the taskTitle state var for description if needed
code = code.replace("dueDate:", "appointmentDatetime:")
code = code.replace("taskType: taskType", "")
code = code.replace("taskType: appointment.taskType", "")
code = code.replace("completedAt:", "updatedAt:")
code = code.replace("assignedTo:", "salesAssociateId:")
code = code.replace("assignedTo", "salesAssociateId")

# 5. Fix field accesses
code = code.replace("appointment.dueDate", "appointment.appointmentDatetime")
code = code.replace("appointment.title", "(appointment.description ?? \"Appointment\")")
code = code.replace("appointment.taskType", "\"Appointment\"")
code = code.replace("appointment.completedAt", "appointment.updatedAt")
code = code.replace("selectedEmployeeId", "salesAssociateId")

# write it back
with open("RSMS_Project/Views/AppointmentManagementView.swift", "w") as f:
    f.write(code)
print("Done fixing properties")
