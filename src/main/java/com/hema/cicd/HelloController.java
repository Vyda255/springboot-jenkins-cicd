package com.hema.cicd;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello viewer,welcome to my project!"
        return "My project is successfully running,and I am happy to see you here!";
    }
}
