module sbylib.engine.shell.interpretor;
// 
// import std;
// import sbylib.engine;
// 
// class Interpretor {
// 
//     private Project proj;
//     private DCD dcd;
// 
//     this(Project proj) {
//         this.proj = proj;
//         this.dcd = new DCD;
//     }
// 
//     ~this() {
//         this.dcd.destroy();
//     }
// 
//     Promise!string interpret(string input) {
//         import std.file : write;
// 
//         auto fileName = tempDir.buildPath("test.d");
//         try {
//             fileName.write(createCode(input));
//         } catch (Exception e) {
//             return promise!({
//                 return e.msg;
//             });
//         }
// 
//         auto mod = new Module!string(proj, fileName);
//         mod.execute();
//         return mod.execution;
//     }
// 
//     string[] complete(string input, long cursorPos) {
//         import std.file : write;
// 
//         auto file = tempDir.buildPath("test.d");
//         file.write(createCode(input));
// 
//         return dcd.complete(file, cursorPos + cursorOffset + 1);
//     }
// 
//     private string createCode(string input) {
//         auto variableList = input
//             .matchAll(ctRegex!`\$\{(.*?)\}`)
//             .map!(m => m.hit)
//             .array;
// 
//         foreach (v; variableList) {
//             auto name = v[2..$-1]; // "${name}"[2..$-1] == "name"
//             if (name !in proj)
//                 throw new Exception(format!`"%s" is not defined.`(v));
//             auto type = proj[name].type.toString.split(".")[$-1];
//             input = input.replace(v, format!`project.get!(%s)("%s")`(type, name));
//         }
// 
//         return createCode().replace("${input}", input);
//     }
// 
//     private long cursorOffset() {
//         auto key = "${input}";
//         return createCode().countUntil(key)-1;
//     }
// 
//     private string createCode() {
//         return q{
//             import sbylib.engine;
//             import sbylib.graphics;
//             ${import}
// 
//             mixin(Register!(func));
// 
//             string func(Project project, EventContext context) {
//                 import std.conv : to;
//                 with (project) {
//                     static if (is(typeof((${input}).to!string))) {
//                         return (${input}).to!string;
//                     } else {
//                         ${input};
//                         return "";
//                     }
//                 }
//             }
//         }.replace("${import}",
//             proj.moduleList.values
//             .map!(m => format!`import %s;`(m.name)).join("\n"));
//     }
// }
