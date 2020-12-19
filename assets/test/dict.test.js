describe("Tests on dict", () => {
    describe("function.ex get", () => {
        it("must be equal to value1", () => {
            chai.expect(W.get({key1: "value1", key2: 2}, "key1")).equal("value1");
        })

        it("must complain about key type", () => {
            chai.expect(
                () => W.get({key1: "value1", 2: "value2"}, 2)
            ).throw("key must be a string");
        })
    });

    describe("function.ex put", () => {
    });
});
