terraform {
 backend "remote" {
   organization = "LanguageTranslator"

   workspaces {
    name = "language_translator"
   }
 }
}


