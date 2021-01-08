# dracoon-ps-covid
Function-based Powershell Script for automated and secure (MFA) distribution of COVID19 test results in collaboration with DRACOON-API.



Die Corona Pandemie stellt viele Organisationen vor ganz neue Herausforderungen. So stellt zum Beispiel der massenhafte Anfall von Ergebnisdokumenten bei den Corona Tests die Institute vor grosse Herausforderungen bei der Übermittlung dieser Ergebnisse direkt an die Getesteten, da es hier plötzlich sehr stark auch auf den Faktor Zeit ankommt.
Hier möchte ich PowershellTemplate zur Verfügung stellen, welches genau für diesen Zweck verwendet werden kann. Als Input soll ein Ordner mit PDF-Dokumente (welche die Testergebnisse enthalten) zur Verfügung stehen. Als weiterer Input wird eine CSV benötigt, welche sämtliche Metainformationen enthält (Mailadresse,  Mobilfunknummer und der zugehörige PDF Name).

Die Sprache Powershell habe ich gewählt, weil diese für Dateihandlung prädestiniert ist und viele IT-Admins darin Kentnisse besitzen. Somit lassen sich hier schnelle Implementierungen realisieren.
Das Script vergleicht zunächst die neu abgelegten Dateien mit den Metadaten. Wird ein Paar aus Testergebnis und getesteter Person gefunden, wir die PDF mit dem Testergebnis nach DRACOON hochgeladen und ein Downloadlink erzeugt. Der Downloadlink und das schützende Kennwort werden dann per Mail und SMS an die Person übermittelt. Wenn die Person das Ergebnis abruft, wird eine Mailnotification an den Versender zugestellt.
Ich hoffe, dass dieses Script in dieser Krise noch vielfach Verwendung finden kann. Natürlich lässt es sich auch relativ leicht an andere Use Cases (Versand von Newslettern, Dienstplänen, Rechnungen etc.) anpassen.

