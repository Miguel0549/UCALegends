package es.uca.legends;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class LegendsApplication {

	public static void main(String[] args) {SpringApplication.run(LegendsApplication.class, args);}

}
