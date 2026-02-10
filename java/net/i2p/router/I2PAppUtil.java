package net.i2p.router;

import java.io.File;
import java.io.IOException;
import javax.swing.JOptionPane;
import net.i2p.router.RouterContext;

public class I2PAppUtil extends WindowsAppUtil {

  public String ServiceUpdaterString() {
    return "http://tc73n4kivdroccekirco7rhgxdg5f3cjvbaapabupeyzrqwv5guq.b32.i2p/news.su3";
  }
  public String ServiceBackupUpdaterString() {
    return "http://dn3tvalnjz432qkqsvpfdqrwpqkw3ye4n4i2uyfr4jexvo3sp5ka.b32.i2p/news.su3";
  }
  public String ServiceStaticUpdaterString() {
    return "http://echelon.i2p/i2p/i2pupdate.sud,http://stats.i2p/i2p/i2pupdate.sud";
  }

  public String getProgramFilesInstall() {
    String programFiles = System.getenv("PROGRAMFILES");
    if (programFiles != null) {
      File i2pDir = new File(programFiles, "i2p");
      File programFilesI2P = new File(i2pDir, "i2p.exe");
      // Only match IzPack installs (have lib/ directory), not our bundled install (has app/ directory)
      File libDir = new File(i2pDir, "lib");
      if (programFilesI2P.exists() && libDir.exists())
        return programFilesI2P.getAbsolutePath();
    }
    String programFiles86 = System.getenv("ProgramFiles(x86)");
    if (programFiles86 != null) {
      File i2pDir = new File(programFiles86, "i2p");
      File programFiles86I2P = new File(i2pDir, "i2p.exe");
      File libDir = new File(i2pDir, "lib");
      if (programFiles86I2P.exists() && libDir.exists())
        return programFiles86I2P.getAbsolutePath();
    }
    return null;
  }

  public boolean checkProgramFilesInstall() {
    String programFiles = System.getenv("PROGRAMFILES");
    if (programFiles != null) {
      File i2pDir = new File(programFiles, "i2p");
      File programFilesI2P = new File(i2pDir, "i2p.exe");
      // Only match IzPack installs (have lib/ directory), not our bundled install (has app/ directory)
      File libDir = new File(i2pDir, "lib");
      if (programFilesI2P.exists() && libDir.exists())
        return true;
    }
    String programFiles86 = System.getenv("ProgramFiles(x86)");
    if (programFiles86 != null) {
      File i2pDir = new File(programFiles86, "i2p");
      File programFiles86I2P = new File(i2pDir, "i2p.exe");
      File libDir = new File(i2pDir, "lib");
      if (programFiles86I2P.exists() && libDir.exists())
        return true;
    }
    return false;
  }

  public boolean promptUserInstallStartIfAvailable() {
    if (!"windows".equals(osName())) {
      return true;
    }
    if (checkProgramFilesInstall()) {
      String message = "It appears you have an existing, unbundled I2P router installed.\n";
      message += "If you click \"Yes\", it will be launched instead.\n";
      message += "If you click \"No\", the Easy-Install router will be launched instead.\n";
      int a = JOptionPane.showConfirmDialog(null, message,
                                        "Existing I2P installation detected",
                                        JOptionPane.YES_NO_OPTION);
      if (a == JOptionPane.NO_OPTION) {
        // User chose to use bundled router instead
        return true;
      }
      // User chose to launch the existing install
      try {
        String pfi = getProgramFilesInstall();
        if (pfi != null) {
          Runtime.getRuntime().exec(new String[] {pfi});
          return false; // Don't also launch bundled router
        }
      } catch (IOException e) {
        // If existing install fails to launch, fall back to bundled router
        return true;
      }
    }
    return true; // No existing install found, proceed with bundled router
  }
}
