// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

let channel = socket.channel("twitter", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

$(document).ready(function () {
  channel.on('notify', function (payload) {
    $("#ul").append(checkList(payload))
    // $("#ul").append("<li> user  :" + payload.user + ", tweet : " + payload.tweet + "</li>")
    console.log(payload)
  })

  var twitterName = $("#user_name")
  var login = document.getElementById("login")
  var logout = document.getElementById("logout")
  var signup = document.getElementById("signup")
  var dashboardDiv = document.getElementById("dashboardDiv")
  var loginDiv = document.getElementById("loginDiv")
  var tweetBtn = document.getElementById("tweetBtn")

  signup.addEventListener("click", function () {
    var username = document.getElementById("username").value
    var password = document.getElementById("password").value
    if (username && password) {
      channel.push("register_user", { user: username, password: password })
        .receive("ok", resp => {
          alert(resp["message"])
        })
        .receive("error", resp => { alert(resp["message"]) })
    } else {
      alert("Oops! Can't login without filling Username/Password")
    }
  })

  login.addEventListener("click",function () {
    var username = document.getElementById("username").value
    var password = document.getElementById("password").value
    if (username && password) {
      channel.push("login_user", { user: username, password: password })
        .receive("ok", resp => {
          window.userToken = username
          twitterName.text(username)
          console.log(resp["message"])
          
          loginDiv.style.display = "none"
          dashboardDiv.style.display ="block"
        })
        .receive("error", resp => { alert(resp["message"]) })
    } else {
      alert("Oops! Can't login without filling Username/Password")
    }
  })

  logout.addEventListener("click",function () {
    console.log("Logging out")
    channel.push("logout_user", { user: window.userToken })
      .receive("ok", resp => {
        console.log(resp)
        clearAll()
      }).receive(
        "error", resp => {
          console.log(resp)
        }
      )
  })

  tweetBtn.addEventListener("click", function () {
    var tweet = document.getElementById("tweetBox").value

    if (tweet) {
      channel.push("tweet", { user: window.userToken, tweet: tweet })
        .receive("ok", resp => {
          console.log(resp)
          $("#ul").append("<li>" + tweet + "</li>")
        })
        .receive("error", resp => {
          alert(resp["message"])
        })
      console.log("Posting tweet " + tweet)
      $("#tweetBox").val('')
    } else {
      alert("No tweet")
    }
  })

  var retweet = $("#chkRetweetBtn")
  retweet.click(function () {
    var tweetId = $('input[name=retweet_id]:checked').val()

    if (tweetId) {
      channel.push("retweet", { user: window.userToken, tweet_id: tweetId })
        .receive("ok", resp => {
          console.log(resp)
          $("#ul").append(checkList(resp.message))
          $('input[name=retweet_id]:checked').prop('checked', false)
        }).receive("error", resp => {
          alert(resp.message)
        })
    } else {
      alert("Select a tweet to Retweet.")
    }
    console.log()
  })

  function clearAll() {
    window.userToken = null
    $("#username").val('')
    $("#password").val('')
    loginDiv.style.display = "block"
    dashboardDiv.style.display ="none"
  }

  function checkList(map) {
    var list = '<li>' + '<div style="display: inline-block; width: 25%;">' + new Date(map.time).toLocaleString() + '</div>'
      + '<div style="display: inline-block; width: 60%;">' + map.user + ': ' + map.tweet + '</div>'

    if (map.user !== window.userToken) {
      list = list + '<div style="display: inline-block; width: 10%;">' 
                  + '<input type="radio" name="retweet_id" value="' + map.tweetid + '">' + '</div>' }
      
    list += '</li>'
    return list;
  }
  })

  // Subscribe
  var subscribe = document.getElementById("subscribeBtn")
  subscribe.addEventListener("click", function () {
    var username = document.getElementById("username").value
    console.log(username)
    var subscribeUsername = document.getElementById("subscribeBox").value
    console.log(subscribeUsername)
    if (subscribeUsername) {
      channel.push("subscribe_user", { user: username, following: subscribeUsername })
        .receive("ok", resp => {
          alert(resp["message"])
          subscribeUsername
        })
        .receive("error", resp => { alert(resp["message"]) })
    } else {
      alert("Type Username to subscribe")
    }
  })

  function clearHashtagTable() {
    var hashtagTable = document.getElementById("htgTable")
    var rowCount = hashtagTable.rows.length;
    while (rowCount >= 0) {
      hashtagTable.deleteRow(rowCount - 1);
      rowCount--;
    }
  }

  // Search by Hashtag
  var htgBtn = document.getElementById("htgBtn")
  htgBtn.addEventListener("click", function () {
    var htg = document.getElementById("htgBox").value
    if (htg) {
      channel.push("search_tweets_by_hashtag", htg)
        .receive("ok", resp => {
          clearHashtagTable()
          var htgTable = document.getElementById("htgTable")
          var tweet = resp["result"]
          for (var i = 0; i < tweet.length; i++) {
            var row = htgTable.insertRow()
            var cell = row.insertCell()
            console.log(tweet[i])
            cell.innerHTML = tweet[i]
          }
        })
        .receive("error", resp => { alert("No such tweets with hashtag " + htg) })
    } else {
      alert("Type Hashtag to look for tweets")
    }
  })

  function clearMentionTable() {
    var mentionTbl = document.getElementById("myMentionTable")
    var rowCount = mentionTbl.rows.length;
    while (rowCount >= 0) {
      mentionTbl.deleteRow(rowCount - 1);
      rowCount--;
    }
  }

  var myMentionBtn = document.getElementById("myMentionBtn")
  myMentionBtn.addEventListener("click", function () {
    var myMention = document.getElementById("username").value
    console.log(myMention)
    if (myMention) {
      channel.push("search_my_mentions", myMention)
        .receive("ok", resp => {
          clearMentionTable()
          var myMentionTable = document.getElementById("myMentionTable")
          var tweet = resp["result"]
          for (var i = 0; i < tweet.length; i++) {
            var row = myMentionTable.insertRow()
            var cell = row.insertCell()
            console.log(tweet[i])
            cell.innerHTML = tweet[i]
          }
        })
        .receive("error", resp => { alert("No tweets found with mention " + myMention) })
    } else {
      alert("Please fill mention to query")
    }
  });