package main

import "core:fmt"
import "core:os"
import conv "core:strconv"
import s "core:strings"
import t "core:time"
import "core:math"

main :: proc() {

    fmt.println("Enter full file path : ")
    buf: [256]u8
    iRead:int
    iRead, _ = os.read(os.stdin, buf[:])
    fmt.printf("Reading file at %s",string(buf[:iRead]))


    //if !os.is_dir(string(buf[:iRead])){
    //    fmt.println("not a file.")
    //    return
    //}
    
    readSize:int=0
    {
    newnum:[32]u8
    numSize:=0
    for (readSize<=0){
    fmt.println("How big should the files be? (in MB)")
    numSize,_ = os.read(os.stdin, newnum[:])
    readSize,_ = conv.parse_int(string(newnum[:]))
    }
    }
    
    fmt.printf("Alright, will try to split into %iMB size files\n", readSize)
    splitFile(string(buf[:iRead-1]),readSize)
}

splitFile :: proc(file: string, BUFFSIZE: int) {
    //BUFFSIZE::399_000_000
    

    filehandle: os.Handle
    ok:os.Error
    if filehandle, ok = os.open(file); ok == nil{
        fmt.println("opened")
    }
    else{
        fmt.println("failed to open file")
        fmt.println("error : ", ok)
        return
    }
    
    defer os.close(filehandle)


    MBBUFFSIZE:=BUFFSIZE
    MBBUFFSIZE*=1_000_000
    buf := make([dynamic]u8)
    defer delete(buf)

    fmt.println(os.get_current_directory())
    
    {
        moveon:=false
        size:i64
        newnum:[32]u8
        size, _ = os.file_size(filehandle)
        fmt.println("file size in MB: ",size/1_000_000)

        for moveon == false {
        count:= i64(math.ceil_f64(f64(size) / f64(MBBUFFSIZE)))
        if 20 < count || 3 > count {
            fmt.printf("This will create %i files. Are you sure you want this many files?\n", count)
            fmt.println("n == NO you probably don't; y == yes, I want ",count)
            answer:[24]u8
            for (answer[0] != 'y' && answer[0] != 'n'){
                _,_ = os.read(os.stdin, answer[:])
            }
            if answer[0] == 'n' || MBBUFFSIZE == 0{
                fmt.println("Please resize")
                _,_ = os.read(os.stdin, newnum[:])
                readSize:int=0
                readSize,_ = conv.parse_int(string(newnum[:]))
                MBBUFFSIZE = readSize * 1_000_000
            }
            else{moveon=true}
        }
        else {
            moveon=true
        }
        }
    }
    resize(&buf, MBBUFFSIZE)

    //find last slash to make the file look nicer.
    periodIndex :int=0
    foundPeriod:=false
    {
    i:=0
    i = s.index(file[i:], "/")
    periodIndex += i
    for i>=0{
    i = s.index(file[periodIndex+1:], "/")
    if i<0 {
        break
    }
    i+=1
    periodIndex += i
    }

    //get last period index.
    i=periodIndex
    i = s.index(file[i:], ".")
    if i>0 {
    periodIndex += i
    foundPeriod=true
    }
    for i>=0{
    i = s.index(file[periodIndex+1:], ".")
    if i<0 {
        break
    }
    i+=1
    periodIndex += i
    }
    }
    
    maxSize:=len(buf)
    read:int=0
    len:=1
    err:os.Error=nil
    i:=0
    offset:i64=0
    destination:string
    defer delete(destination)

    for(len>0){
    resize(&buf, MBBUFFSIZE)
    len, err =os.read_at(filehandle, buf[:maxSize], offset)
    if err != nil {
        fmt.println("Something broke! can't read the file because : ", err)
        delete(destination)
        return
    }
    
    //len will be 0 when there is nothing to read. Happens after hitting EOF on a read.
    if len == 0 {
        continue
    }
    
    if foundPeriod == true {
    destination=fmt.aprintf("%s%i%s", file[:periodIndex], i, file[periodIndex:])
    }
    else{
        destination=fmt.aprintf("%s%i", file[:], i)
    }
    
    offset+=i64(len)
    
    succeed := os.write_entire_file(destination[:], buf[:len])
    if succeed == false {
        fmt.println("failed to write to ", destination)
        break
    }
    fmt.println(destination)
    fmt.println("Created new file of size : ",len/1_000_000, "MB")
    clear(&buf)
    i+=1
    }
}
