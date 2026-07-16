/* FizzBuzz
    divisible by 3 => Fizz
    divisible by 5 => Buzz
    divisible by 3 and 5 => FizzBuzz
*/
import * as fs from "fs";

const input = fs.readFileSync(0, "utf8").trim().split(/\s+/);

const numbers = input.map(Number);

console.log("you entered");
console.log(numbers);