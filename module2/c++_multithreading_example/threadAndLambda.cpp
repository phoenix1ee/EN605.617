#include <thread>
#include <iostream>
#include <string>

//lambda: [](){},...The brackets tell the lambda which variables from the surrounding scope it is allowed to use.
//[] capture clause
//[] capture nothing
//[x] capture x by value (copy)
//[&x] capture x by reference
//[=] capture everything by value
//[&] capture everything by reference
//[x,&y] mixed use of value and reference

//() is used to specify types and name of arguments to be used inside {}
//{} the actuall processing
//,... the arguments

void task1(std::string msg){std::cout<<"task1 says:"<<msg;}
int main(){
    int dummy[2]={0,0};
    std:: thread t0([&dummy](int i) {dummy[0]=dummy[0]+i;},1);
    std:: thread t1([&dummy](int i) {dummy[1]=dummy[1]+i;},2);
t0.join();
t1.join();
std::cout<<dummy[0]<<dummy[1];
}