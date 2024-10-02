_ = require 'underscore'
async = require "async"
config = require '../../../config'
moment    = require 'moment'
fs = require('fs')
readline = require('readline')

#example:  ./node_modules/coffeescript/bin/coffee scripts/custom/rbo/rads_to_mailchimp_sync.coffee


config.resolve (
  logger
  Secure
  User
  api_rbo
  APITOKEN_RB
) ->

  tenantId = "53a28a303f1e0cc459000127" #DEV
  #tenantId = "5684a2fc68e9aa863e7bf182" #RBO
  userTotal = 0
  userCount = 0
  typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

  emailsIndex = {}
  stateReminders = {}
  members = []
  reps = []
  missingClientIds = []
  duplicateEmails = []
  updated = []

  clientIds = ["xxx","yyy"]

  UNSUBSCRIBED_EMAILS = {}

  readFile = (done) ->
    #Read in a file
    rl = readline.createInterface(
      {
        input: fs.createReadStream('/Users/scottwallace/Desktop/Main/GotMyTag/RollingBones/Mailchimp/unsubscribed_segment.csv')
        crlfDelay: Infinity
      }
    )
    rl. on 'line', (line) ->
      email = line.split(",")[0].trim().toLowerCase() if line
      UNSUBSCRIBED_EMAILS[email] = email
      #console.log "DEBUG: email: ", email
    rl.on 'close', () ->
      console.log "DEBUG: DONE READING FILE"
      return done()


  processUser = (user, done) ->
    #return next null  #Skip processing this user
    userCount++
    #return done null unless userCount > 1400
    console.log "****************************************Processing #{userCount} of #{userTotal}, #{user.first_name} #{user.last_name}, userId: #{user._id}"

    #Update stateReminders
    if user.reminders?.email is true and user.reminders?.states?.length > -1
      stateReminders[user._id.toString()] = {
        emailFlag: user.reminders.email
        states: user.reminders.states
      }

    #Update member count
    if user.isMember
      members.push {userId: user._id.toString(), name: user.name, clientId: user.clientId, email: user.email}

    #Update rep count
    if user.isRep
      reps.push {userId: user._id.toString(), name: user.name, clientId: user.clientId, email: user.email}

    #Update missing ClientIds count
    if !user.clientId
      missingClientIds.push {userId: user._id.toString(), name: user.name, clientId: user.clientId, email: user.email}

    #Duplicate users
    emailsIndex[user.email] = [] unless emailsIndex[user.email]
    emailsIndex[user.email].push {userId: user._id.toString(), name: user.name, clientId: user.clientId, email: user.email}

    #Update Mailchimp preferences
    console.log "DEBUG: user.email: ", user.email
    if user.subscriptions?.hunts?
      console.log "DEBUG: Skipping user already has subscriptions set: ", user.subscriptions
      return done null
    else if user.email and UNSUBSCRIBED_EMAILS[user.email.trim().toLowerCase()]
      console.log "DEBUG: FOUND UNSUBSCRIBE EMAIL, DON'T UPDATE: ", user.email
      return done null
    else if user.email #and user._id.toString() is "56e1ddcd88dd0cd7091ccd57"
      body = {}
      json = (content, errCode) ->
        if errCode
          console.log "response returned with: ", content
          console.log "response returned with errCode: ", errCode
        return done null
      res = {
        json: json
      }

      params = {
        direct: true
        token: APITOKEN_RB
        hunts: "false"
        rifles: "false"
        products: "false"
        newsletters: "false"
        state_reminders_text: "false"
        state_reminders_email: "false"
      }

      params.state_reminders_email = "true" if user.reminders?.email and (user.reminders?.types?.indexOf("app-start") > -1 or user.reminders?.types?.indexOf("app-end") > -1)
      params.state_reminders_text = "true" if user.reminders?.text and (user.reminders?.types?.indexOf("app-start") > -1 or user.reminders?.types?.indexOf("app-end") > -1)

      params.hunts = "true" if user.isMember or user.isRep
      params.rifles = "true" if user.isMember or user.isRep
      params.products = "true" if user.isMember or user.isRep
      params.newsletters = "true" if user.isMember or user.isRep

      params.hunts = "true" if user.subscriptions?.hunts is true
      params.rifles = "true" if user.subscriptions?.rifles is true
      params.products = "true" if user.subscriptions?.products is true
      params.newsletters = "true" if user.subscriptions?.newsletters is true

      req = {
        params: params
        body: body
        user: user
      }
      updated.push user.email
      if false
        api_rbo.user_notifications req, res
      else
        console.log "updating user notifications for req: ", req.params, req.body
        return done null

    else
      return done null


  async.waterfall [

    # Read input file
    (next) ->
      readFile () ->
        return next null

    # Get users
    (next) ->
      console.log 'getting users'
      singleUserTest = false

      if singleUserTest
        userId = "5684b5e5769bca1267868a07"
        User.findById userId, {internal: true}, next
      else
        conditions = {
          tenantId: tenantId
          isMember: true
        }
        console.log "DEBUG: user query conditions", JSON.stringify(conditions)
        User.find(conditions).lean().exec (err, users) ->
          next err, users
#        User.findByTenant tenantId, {internal: true}, (err, users) ->
#          next err, users

    # For each user, do stuff
    (users, next) ->
      users = [users] unless typeIsArray users
      console.log "found #{users.length} users"
      userTotal = users.length
      async.mapSeries users, processUser, (err) ->
        for email in Object.keys(emailsIndex)
          duplicateEmails.push emailsIndex[email] if emailsIndex[email]?.length > 1
        next err

  ], (err) ->

    console.log "Finished"
    console.log "stateReminders: ", Object.keys(stateReminders).length
    console.log "members: ", members.length
    console.log "reps: ", reps.length
    console.log "missing client ids: ", missingClientIds.length
    console.log "emailsIndex: ", Object.keys(emailsIndex).length
    console.log "duplicateEmails: ", duplicateEmails.length
    console.log "updated: ", updated.length

    if err
      logger.error "Found an error", err
      process.exit(1)
    else
      console.log "Done"
      process.exit(0)
