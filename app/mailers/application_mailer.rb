class ApplicationMailer < ActionMailer::Base
  default from: "Mes2Vis <notifications@mes2vis.com>",
          reply_to: "support@mes2vis.com"
  layout "mailer"
end
