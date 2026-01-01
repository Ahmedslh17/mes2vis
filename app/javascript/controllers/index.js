import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import PasswordController from "controllers/password_controller"
application.register("password", PasswordController)

eagerLoadControllersFrom("controllers", application)
