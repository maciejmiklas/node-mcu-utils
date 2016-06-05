import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public class TestGenerator {

    private static long getSecFromYear(int year) {
	LocalDateTime date = LocalDateTime.of(year, 1, 1, 0, 0, 0);
	long secs = date.atZone(ZoneId.of("UTC")).toInstant().toEpochMilli() / 1000;
	return secs;
    }

    public static void main(String... a) throws IOException {
	{
	    System.out.println("1980 " + getSecFromYear(1980));
	    System.out.println("1990 " + getSecFromYear(1990));
	    System.out.println("2000 " + getSecFromYear(2000));
	    System.out.println("2010 " + getSecFromYear(2010));
	    System.out.println("2015 " + getSecFromYear(2015));
	    System.out.println("2020 " + getSecFromYear(2020));
	    System.out.println("2025 " + getSecFromYear(2025));
	}

	{
	    DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

	    try(BufferedWriter out = Files.newBufferedWriter(Paths.get("datesGMT.csv"))) {
		LocalDateTime date = LocalDateTime.now();
		for (int i = 0; i < 5000; i++) {
		    date = date.plusHours(16).plusSeconds(6).minusMinutes(5);
		    String formatted = date.format(df);
		    long secs = date.atZone(ZoneId.of("UTC")).toInstant().toEpochMilli() / 1000;
		    out.write(secs + ","+ formatted + "\n");
		}
	    }
	}
    }
}