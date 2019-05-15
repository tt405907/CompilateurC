import subprocess
import os
subprocess.Popen(["bison", "-d","yacc1.y"], shell=True).wait()

subprocess.Popen(["flex", "lex1.l"], shell=True).wait()

subprocess.Popen(["gcc", "-o", "text.exe", "yacc1.tab.c" ,"lex.yy.c"], shell=True).wait()


for name in os.listdir("Tests"):
    if name[-1] == "c":
        print(name)
        subprocess.Popen([".\\text.exe" ,".\\"+"Tests\\"+name], shell=True).wait()
        
        subprocess.Popen(["dot", "-Tpdf", "file.dot", "-o" ,"pdfs\\"+name[:-2]+".pdf"], shell=True).wait()
        

