defmodule PhoenixLive.Mailer.Resend do
  def send_application_notification(application) do
    recipient_email = Application.get_env(:phoenix_live, :recipient_email) || "recruiter@company.com"
    api_key = Application.get_env(:phoenix_live, :resend_api_key)

    email_body = """
    Nova candidatura recebida!

    Nome: #{application.name}
    E-mail: #{application.email}
    Telefone: #{application.phone}
    CEP: #{application.zip_code}

    Formação: #{application.education}

    Habilidades:
    #{application.skills}

    Carta de Apresentação:
    #{application.cover_letter}

    GitHub: #{application.github_url || "Não informado"}
    LinkedIn: #{application.linkedin_url || "Não informado"}

    Currículo: #{application.resume_url}
    """

    payload = %{
      from: "candidaturas@yourdomain.com",
      to: [recipient_email],
      subject: "Nova Candidatura - #{application.name}",
      text: email_body
    }

    Req.post!("https://api.resend.com/emails",
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ],
      json: payload
    )
  end
end
