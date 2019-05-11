import subprocess
import os
subprocess.call(["flex", "lex1.l"], shell=True)
subprocess.call(["bison", "-g","yacc1.y"], shell=True)
subprocess.call(["gcc", "-o", "text.exe", "yacc1.tab.c" ,"lex.yy.c"], shell=True)

for name in os.listdir("Tests"):
    if name[-1] == "c":
        print(name)
        subprocess.call([".\\text.exe" ,".\\"+"Tests\\"+name], shell=True)
        subprocess.call(["dot", "-Tpdf", "file.dot", "-o" ,"pdfs\\"+name[:-2]+".pdf"], shell=True)

