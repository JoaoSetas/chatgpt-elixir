// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, timeout: 60000 })
// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.phxPageLoadingCount = 0
window.addEventListener("phx:page-loading-start", _info => window.phxPageLoadingCount++ && topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => window.phxPageLoadingCount && !--window.phxPageLoadingCount && topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


// ---------------------- Custom JS ----------------------
// ---------------------- Autoscroll ----------------------

// Register the event listeners
window.addEventListener(`phx:streaming_started`, streaming_started);
window.addEventListener(`phx:streaming`, streaming);
window.addEventListener(`phx:streaming_finished`, streaming_finished);

// The event listener callback function
function streaming_started(_event) {
  userScroll = false;
  autoScroll = false;
  scrollToTop();
}

// The event listener callback function
function streaming(_event) {
  scrollToBottom();
}

// The event listener callback function
function streaming_finished(_event) {
  scrollToTop();
}

// Get the button
let mybutton = document.getElementById("btn-back-to-top");
// When the user clicks on the button, scroll to the top of the document
mybutton.addEventListener("click", scrollButton);
let userScroll = false;
let autoScroll = false;

function scrollButton() {
  userScroll = false;
  scrollToTop();
  userScroll = true;
}

// When the user scrolls down 20px from the top of the document, show the button
window.onscroll = function onscroll() {
  if (autoScroll) {
    autoScroll = false;
  } else {
    userScroll = true;
  }
  scrollFunction();
};

// When the user scrolls down 20px from the top of the document, show the button
function scrollFunction() {
  if (
    document.body.scrollTop > 10 ||
    document.documentElement.scrollTop > 10
  ) {
    mybutton.style.display = "block";
  } else {
    mybutton.style.display = "none";
  }
}

// When the user clicks on the button, scroll to the top of the document
function scrollToTop() {
  if (userScroll) {
    return;
  }

  autoScroll = true;

  window.scroll({
    top: 0,
    behavior: 'smooth'
  });
}

// Scroll to bottom
function scrollToBottom() {
  if (userScroll) {
    return;
  }
  autoScroll = true;

  window.scroll({
    top: document.body.scrollHeight
  });

  scrollFunction();
}

// Get the audio stream from the user's microphone
navigator.mediaDevices.getUserMedia({ audio: true })
  .then(function (stream) {
    // Create a new MediaRecorder object to record the stream
    let recorder = new MediaRecorder(stream);

    // Create an array to store the recorded audio chunks
    let chunks = [];

    // When the recorder starts recording, log a message to the console
    recorder.addEventListener('start', function () {
      chunks = [];
      document.getElementById('question').value = "Recording started... (press again to stop)";
      document.getElementById("start-recording").classList.add("bg-red-800");
    });

    // When data is available from the recorder, add it to the chunks array
    recorder.addEventListener('dataavailable', function (event) {
      chunks.push(event.data);
    });

    // When the recorder stops recording, create a new Blob from the chunks array
    // and create a new URL for the Blob
    recorder.addEventListener('stop', function () {
      window.dispatchEvent(new Event("phx:page-loading-start"));
      document.getElementById("start-recording").classList.remove("bg-red-800");

      let blob = new Blob(chunks, { 'type': 'audio/ogg; codecs=opus' });
      let file = new File([blob], "audio.ogg", { type: "audio/ogg" });
      let data = new FormData();
      data.append('audio', file);

      // Download the recorded audio to the server
      fetch('/upload-audio', {
        body: data,
        credentials: 'same-origin',
        method: "POST"
      })
        .then(response => response.json())
        .then(data => {
          document.getElementById("question").value = data.text;
          window.dispatchEvent(new Event("phx:page-loading-stop"));
        })
        .catch(function (error) {
          console.error('Error uploading audio:', error);
          window.dispatchEvent(new Event("phx:page-loading-stop"));
        });
    });

    // Start recording when the user clicks a button
    document.getElementById('start-recording').addEventListener('click', function () {
      if (recorder.state == "recording") {
        recorder.stop();
      } else {
        recorder.start();
      }
    });

  })
  .catch(function (error) {
    console.error('Error getting audio stream:', error);
  });
