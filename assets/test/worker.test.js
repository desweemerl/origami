describe("Test on worker", () => {
    before(async () => {
        await W.createWorker("base/test/workers/init.js", "worker1");
    });

    describe("Worker", () => {
        it("send \"ping\" receive \"pong\"", (done) => {
            W.receive(W.matchFn({action: "pong"}, function _pongReceiver() {
                done();
            }))
            W.send("worker1", {action: "ping"});
        });
    });
});
