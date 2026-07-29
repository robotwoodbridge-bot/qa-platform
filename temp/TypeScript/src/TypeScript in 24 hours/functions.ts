
console.log("========== Function with no param and return ============================")
function greet(){
    console.log("hi");
}

greet();

console.log("========== Function with Params and return type ============================")
function add(x:number, y:number): number {
    return x + y;
}

console.log("adding 5 + 6 is: ", add(5,6));

console.log("========== Function with option/default param ============================")
function greeting(name:string, mssg:string = "Hello"): void {
    console.log(mssg, name)
}

greeting("Alice");
greeting("Tim", "Hi");
greeting("Jerry", "Good Morning")

