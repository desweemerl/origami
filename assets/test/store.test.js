describe("Tests on store", () => {
    describe("function.ex set", () => {
        it("must be equal to value1 with object", () => {
            const store = W.storeFactory();
            store.set("value1", "key1");

            chai.expect(store.get()).eql({key1: "value1"});
            chai.expect(store.getTouchedPaths()).eql([["key1"]]);
        });

        it("must be equal to value1 with array", () => {
            const store = W.storeFactory([]);
            store.set("value1", 0);

            chai.expect(store.get()).eql(["value1"]);
            chai.expect(store.getTouchedPaths()).eql([[0]]);
        });

        it("must create object", () => {
            const store = W.storeFactory();

            store.set("value1", "key1");
            store.set("value2", ["key2", "key3"]);

            chai.expect(store.get()).eql({key1: "value1", key2: {key3: "value2"}});
            chai.expect(store.getTouchedPaths()).eql([["key1"], ["key2", "key3"]]);

            store.markAsUntouched();
            chai.expect(store.getTouchedPaths()).eql([]);
        });

        it("must create array", () => {
            const store = W.storeFactory();

            store.set("value1", "key1");
            store.set("value2", ["key2", 0]);

            chai.expect(store.get()).eql({key1: "value1", key2: ["value2"]});
            chai.expect(store.getTouchedPaths()).eql([["key1"], ["key2", 0]]);

            store.markAsUntouched();
            chai.expect(store.getTouchedPaths()).eql([]);
        });

        it("must complain about key type with object ", () => {
            const store = W.storeFactory();

            chai.expect(
                () => store.set("value2", [0, "key2"])
            ).throw("key must be a string");
        });

        it("must complain about index type with array", () => {
            const store = W.storeFactory([]);

            chai.expect(
                () => store.set("value1", ["key1"])
            ).throw("index must be a Number");
        });
    });
});
