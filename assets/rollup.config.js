import flowEntry from "rollup-plugin-flow-entry";
import flow from "rollup-plugin-flow";

const files = ["main", "worker"];

export default files.map((file) =>
    ({
        input: `src/${file}.js`,
        output: {
            file: `dist/${file}.js`,
            format: "iife",
            name: "W",
        },
        plugins: [flow({pretty: true}), flowEntry()],
        watch: {
            include: "src/*.js"
        }
    })
);
