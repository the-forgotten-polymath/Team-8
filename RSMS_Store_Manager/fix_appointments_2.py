import re

with open("RSMS_Project/Views/AppointmentManagementView.swift", "r") as f:
    code = f.read()

# Fix $0.dueDate -> $0.appointmentDatetime
code = code.replace("$0.dueDate", "$0.appointmentDatetime")
code = code.replace("$1.dueDate", "$1.appointmentDatetime")

# Fix $0.completedAt -> $0.updatedAt
code = code.replace("$0.completedAt", "$0.updatedAt")
code = code.replace("$1.completedAt", "$1.updatedAt")

# Fix priority
code = code.replace("appointment.priority.lowercased()", "\"medium\"")
code = code.replace("appointment.priority", "\"Medium\"")
code = code.replace("priority: appointment.priority,", "")

# Fix title
code = code.replace("$0.title", "($0.description ?? \"\")")

# Fix `.appointment {`
code = code.replace(".appointment { await loadData() }", ".task { await loadData() }")
code = code.replace(".appointment { await loadCompletedTasks() }", ".task { await loadCompletedTasks() }")

# Fix initializers
def fix_init(match):
    return '''let newAppointment = Appointment(
                id: newTaskId,
                customerId: nil,
                storeId: SessionManager.shared.currentUser?.storeId ?? UUID(),
                salesAssociateId: salesAssociateId,
                appointmentDatetime: dueDate,
                description: description,
                status: "open",
                createdBy: SessionManager.shared.currentUser?.id,
                createdAt: Date(),
                updatedAt: Date()
            )'''
code = re.sub(r'let newAppointment = Appointment\([\s\S]*?updatedAt: nil[\s\S]*?\)', fix_init, code)

def fix_update(match):
    return '''let updated = Appointment(
            id: appointment.id, 
            customerId: appointment.customerId,
            storeId: appointment.storeId, 
            salesAssociateId: appointment.salesAssociateId, 
            appointmentDatetime: appointment.appointmentDatetime,
            description: appointment.description, 
            status: "done", 
            createdBy: appointment.createdBy, 
            createdAt: appointment.createdAt, 
            updatedAt: Date()
        )'''
code = re.sub(r'let updated = Appointment\([\s\S]*?updatedAt: Date\(\)[\s\S]*?\)', fix_update, code)


with open("RSMS_Project/Views/AppointmentManagementView.swift", "w") as f:
    f.write(code)
print("Done fixing second round")
