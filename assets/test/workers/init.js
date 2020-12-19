importScripts("../../dist/worker.js");

W.receive(
    W.matchFn({action: "ping"}, function _pingReceiver() {
        W.send({action: "pong"});
    })
);

