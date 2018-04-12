/*
 *
 *
 * This software is only to be used for the purpose for which it has been
 * provided. No part of it is to be reproduced, disassembled, transmitted,
 * stored in a retrieval system nor translated in any human or computer
 * language in any way or for any other purposes whatsoever without the prior
 * written consent
 */
package com.jade.samples;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A very simple RESTful web service.
 */
@RestController
@EnableAutoConfiguration
public class SampleRestController {

    private static final Logger LOGGER = LoggerFactory.getLogger(SampleRestController.class);


    private static Random rand = new Random();
    private static int value = rand.nextInt(50);

    /**
     * The hello endpoint.
     *
     * @return a String response.
     */
    @RequestMapping("/hello")
    public String hello() {
        LOGGER.info("Syslog output from Platform-Example-Spring application");
        java.util.Properties props = System.getProperties();
        LOGGER.debug("Instance Random Identifier:" + value);
        return "Platform Example Spring Boot Application Sucessfully deployed ! " + value;
    }

    public static int getValue() {
      return value;
    }

    /**
     * The entry point for the Hello World PoC application.
     *
     * @param args The command line arguments.  Not used.
     * @throws Exception if something goes wrong.
     */
    public static void main(final String[] args) throws Exception {
        SpringApplication.run(SampleRestController.class, args);
    }
}
