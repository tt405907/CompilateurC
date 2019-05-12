import subprocess
import os
print("hello1")
subprocess.call(["lex", "lex1.l"])
print("hello2")
subprocess.call(["yacc", "-g","yacc1.y"])
print("hello3")
subprocess.call(["gcc", "-o", "executable", "y.tab.c" ,"lex.yy.c"])
print("hello")
for name in os.listdir("Tests"):
    print(name)
    if name[-1] == "c":
        print(name)
        subprocess.call(["./executable" ,"./"+"Tests/"+name])
        subprocess.call(["dot", "-Tpdf", "file.dot", "-o" ,"pdfs/"+name[:-2]+".pdf"])
