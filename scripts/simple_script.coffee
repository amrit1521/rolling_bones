_ = require 'underscore'
async = require "async"
config = require '../config'
winston     = require 'winston'
moment    = require 'moment'

config.resolve (
  logger
  Secure
  User

) ->

  tenantId = "54a8389952bf6b5852000007"
  userTotal = 0
  userCount = 0
  typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

  clientIds = ["01678","03301","04000","04000","01830","01830","03193","03193","04061","03664","03664","04943","04943","01369","05827","05827","01651","01964","03800","03800","01300","02827","02827","01384","03854","03854","00448","00448","03589","03589","02565","02565","03751","04024","04024","02830","02830","04084","04084","04113","04115","04117","04117","02861","02861","01472","01472","04700","04700","03425","01216","01216","02526","02913","01715","03043","03043","04001","01345","01345","04525","02354","05961","05961","00488","04059","04059","07049","07049","04080","01590","01590","02970","02643","02643","04669","03268","03263","03536","02729","02729","04025","04025","04494","04494","01383","01534","00468","00469","00469","00468","04034","04195","03165","03165","00130","02990","02990","03101","03102","02929","03071","03968","00361","00361","00426","00427","03267","03267","00117","00117","03495","03478","02164","01627","01627","03076","03076","03041","02270","00315","00315","01818","01818","01732","02344","03991","03552","03552","02352","00560","00560","03553","03553","01702","01702","04017","04194","04194","01227","01226","02928","02698","01597","03047","03047","01358","03766","03766","02743","04150","04150","02803","03676","03418","04106","02083","02083","01899","00436","00436","01684","01684","04093","04093","01629","03357","03357","01279","04713","04713","00034","00034","06872","06872","03422","04076","02549","03592","01967","04449","05619","01868","01868","02919","02919","04160","04160","04161","04161","05729","05729","06054","06054","02052","03835","03835","07140","07140","02006","02006","01827","03092","03092","01787","03541","03541","03966","03487","03487","06718","06718","03772","03427","04046","04046","02432","02432","03469","03469","01677","00437","00437","02829","02829","04087","02545","02545","02343","02343","05621","04402","04402","03398","03398","03752","03752","01547","03133","03133","03134","03134","02841","02841","04167","04167","04168","04168","03443","04279","03213","03213","01523","07192","07192","02586","01526","01526","03992","03992","02539","02539","00218","00218","04118","04118","03201","01307","03738","03738","03600","03599","03575","03598","03361","03361","06709","06251","04813","04813","03437","04738","04738","02906","01990","02156","00125","05617","05617","03945","04146","04146","02773","02773","02254","00347","02333","02333","01937","01938","01936","04751","02629","02623","02623","02108","02108","02458","02458","02415","02415","02002","01710","03428","04340","04340","02491","02491","05826","05826","01285","04784","04784","04786","04786","03972","03972","03099","03099","02831","02831","02033","02033","00438","03096","03096","04251","04235","03539","01607","02468","04009","04009","03629","02888","03163","04092","01486","01486","02616","02616","06992","06992","04125","04008","02538","02538","04018","04396","03501","04600","03975","03039","04010","05653","02865","02865","04485","04485","02942","02942","03378","03379","03379","03506","03368","03368","03369","03369","03716","02633","02633","04774","03172","03172","07062","02179","03057","03057","04476","03463","01751","04374","03578","03578","02272","02272","02271","02271","02902","02902","04734","01883","02025","04200","04199","04045","04045","03282","03282","01324","01324","06724","03145","03145","02710","02710","03543","03543","02761","04192","00110","00110","03566","03764","06911","06911","03954","03648","03648","04173","04098","06084","06084","01961","01961","01963","01963","00585","01649","01649","03679","04392","04392","04069","03990","02421","02421","04060","04060","04278","01301","01301","03029","02320","02320","04055","03207","03207","02232","02232","04072","02860","02860","02958","02958","02682","03025","02638","02638","04319","04319","03243","03243","04487","04487","05544","05544","03089","02840","02840","01846","01846","02012","02012","03146","03146","02798","02797","02799","04389","03562","00379","03288","00140","00140","03492","03617","03617","03637","03637","02900","02900","04166","03624"]

  processUser = (user, done) ->
    #return next null  #Skip processing this user
    userCount++
    #return next null unless userCount < 3
    console.log "****************************************Processing #{userCount} of #{userTotal}, #{user.first_name} #{user.last_name}, userId: #{user._id}"
    return done null


  async.waterfall [

# Get users
    (next) ->
      console.log 'get all users'

      singleUserTest = false

      if singleUserTest
        userId = "525ffd406beefe5465000003"
        User.findById userId, {internal: true}, next
      else
        User.findByTenant tenantId, {internal: true}, (err, users) ->
        #User.index next
        #User.find().lean().exec next
          next err, users

# For each user, do stuff
    (users, next) ->
      users = [users] unless typeIsArray users
      console.log "found #{users.length} users"
      userTotal = users.length
      async.mapSeries users, processUser, (err) ->
        next err

  ], (err) ->
    console.log "Finished"
    if err
      logger.error "Found an error", err
      process.exit(1)
    else
      console.log "Done"
      process.exit(0)
