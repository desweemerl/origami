describe("Tests on array", () => {
    describe("function.ex at", () => {
        it("must be equals to three", () => {
            chai.expect(W.at(["one", "two", "three"], 1)).equal("two");
        });

        it("must be equals to null", () => {
            chai.expect(W.at(["one", "two", "three"], 10)).is.null;
        });

        it("must be equals to four", () => {
            chai.expect(W.at(["one", "two", "three"], 10, "four")).equal("four");
        });

        it("must throw an error", () => {
            chai.expect(() => W.at(["one", "two", "three"], {})).to.throw("index must be a Number");
        });

        it("must throw an error", () => {
            chai.expect(() => W.at("hello", {})).to.throw("data must be an Array");
        });
    });

    describe("fn at", () => {
        it("must be equals to ['one', 'two', 'three']", () => {
            chai.expect(W.updateAt(["one", "three"], 1, "two")).to.eql(["one", "two", "three"]);
        });

        it("must be equals to ['one', 'two']", () => {
            chai.expect(W.updateAt(["one", "two"], 10, "three")).to.eql(["one", "two"]);
        });

        it("must throw an error", () => {
            chai.expect(() => W.updateAt(["one", "two"], {}, "three")).to.throw("index must be a Number");
        });

        it("must throw an error", () => {
            chai.expect(() => W.updateAt("hello", 1, "one")).to.throw("data must be an Array");
        });
    });
});
