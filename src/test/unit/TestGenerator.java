package src.test.unit;

import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.zone.ZoneRules;

public class TestGenerator {

    final static DateTimeFormatter DF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private static long getSecFromYear(int year) {
	LocalDateTime date = LocalDateTime.of(year, 1, 1, 0, 0, 0);
	long secs = date.atZone(ZoneId.of("UTC")).toInstant().toEpochMilli() / 1000;
	return secs;
    }

    private static void printYearOffset() {
	System.out.println("1980 " + getSecFromYear(1980));
	System.out.println("1990 " + getSecFromYear(1990));
	System.out.println("2000 " + getSecFromYear(2000));
	System.out.println("2010 " + getSecFromYear(2010));
	System.out.println("2015 " + getSecFromYear(2015));
	System.out.println("2020 " + getSecFromYear(2020));
	System.out.println("2025 " + getSecFromYear(2025));
    }

    private static void generateDatesUTC() throws IOException {
	try (BufferedWriter out = Files.newBufferedWriter(Paths.get("datesUTC.csv"))) {
	    ZonedDateTime date = ZonedDateTime.now(ZoneOffset.UTC);
	    for (int i = 0; i < 10000; i++) {
		date = date.plusHours(i % 5).plusSeconds(i % 60).plusMinutes(i % 10);
		String formatted = date.format(DF);
		long secs = date.toInstant().toEpochMilli() / 1000;
		out.write(secs + "," + formatted + "\n");
	    }
	}
    }

    private static void generateDates(String cont, String capital) throws IOException {
	try (BufferedWriter out = Files.newBufferedWriter(Paths.get("dates" + cont + "_" + capital + ".csv"))) {
	    ZonedDateTime utcDate = ZonedDateTime.now(ZoneOffset.UTC);
	    for (int i = 0; i < 10000; i++) {
		utcDate = utcDate.plusHours(i % 15).plusSeconds(i % 60).plusMinutes(i % 30);
		long utcSecs = utcDate.toInstant().toEpochMilli() / 1000;
		ZonedDateTime date = ZonedDateTime.ofInstant(utcDate.toInstant(), ZoneId.of(cont + "/" + capital));
		boolean daylightSavings = date.getZone().getRules().isDaylightSavings(date.toInstant());
		out.write(utcSecs + "," + date.format(DF) + "," + (daylightSavings ? "1" : "0") + "\n");
	    }
	}
    }

    public static void main(String... a) throws IOException {
	// printYearOffset();
	generateDatesUTC();
	generateDates("Europe", "London");
	generateDates("Europe", "Warsaw");
	generateDates("Europe", "Bucharest");
	generateDates("America", "Los_Angeles");
    }
}