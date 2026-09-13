package com.zao;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;

public final class ZAOAgent {
    private static final String LOG_NAME = "ZAOAgent.log";

    private ZAOAgent() {
    }

    public static void log(String message) {
        Path logFile = Path.of(System.getProperty("user.home"), "Zomboid", LOG_NAME);
        String line = Instant.now() + " [ZAO] " + message + System.lineSeparator();
        try {
            Files.createDirectories(logFile.getParent());
            Files.writeString(logFile, line, StandardCharsets.UTF_8,
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException exception) {
            System.err.print(line);
        }
    }
}
