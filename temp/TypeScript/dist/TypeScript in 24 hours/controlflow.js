"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
let age = 20;
console.log();
console.log("==================================");
console.log(age);
if (age >= 20) {
    console.log("you are eligible to vote.");
}
console.log("==================================");
let temperture = 36;
if (temperture > 35) {
    console.log("It is too hot.");
}
else {
    console.log('The weather is pleasant.');
}
console.log("=====================================");
let day = "Friday";
switch (day) {
    case "Monday":
        console.log("Start of the week");
        break;
    case "Friday":
        console.log("End of the work week");
        break;
    default:
        console.log("Enjoy your day!");
}
console.log("============ For Loop =========================");
for (let i = 0; i < 5; i++) {
    console.log("i is: ", i);
}
console.log("============ While Loop =========================");
let count = 0;
while (count < 5) {
    console.log("count is: ", count);
    count++;
    if (count === 3) {
        break;
    }
}
console.log("============ Do-While Loop =========================");
let y = 0;
do {
    console.log("y is: ", y);
    y++;
    if (y === 3) {
        continue;
    }
} while (y < 5);
//# sourceMappingURL=controlflow.js.map