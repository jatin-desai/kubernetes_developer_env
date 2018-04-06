/*
 *
 * This software is only to be used for the purpose for which it has been
 * provided. No part of it is to be reproduced, disassembled, transmitted,
 * stored in a retrieval system nor translated in any human or computer
 * language in any way or for any other purposes whatsoever without the prior
 * written consent.
 */
package com.jade.samples.test;

import org.junit.Assert;
import org.junit.Test;
import com.jade.samples.SampleRestController;

/**
 * A test class for the Hello World service.
 */
public class SampleRestControllerTest {
    @Test
    public void validHello() {
        SampleRestController hi = new SampleRestController();
        Assert.assertEquals("Platform Example Spring Boot Application Sucessfully deployed ! " + hi.getValue(), hi.hello());
    }
}
