require 'rails_helper'

describe MailTemplate do
  let(:template) { MailTemplate.create!(title: 'member_activated') }

  specify 'audit subject and content changes' do
    session = create(:session, :admin)
    template.audit_session = session

    expect {
      template.update!(
        subject: 'Bienvenue à toi!',
        content: 'Hello {{ member.name }}')
    }.to change(Audit, :count).by(1)

    audit = template.audits.last
    expect(audit.session).to eq session
    expect(audit.audited_changes['subjects'].last['fr']).to eq 'Bienvenue à toi!'
    expect(audit.audited_changes['contents'].last['fr']).to eq 'Hello {{ member.name }}'
  end

  specify 'set default subject and content for all languages' do
    Current.acp.update! languages: %w[fr de]
    expect(template.subjects).to eq(
      'fr' => 'Bienvenue!',
      'de' => 'Herzlich willkommen!')
    expect(template.contents['fr']).to include('<p>EDITEZ-MOI!</p>')
    expect(template.contents['de']).to include('<p>MICH BEARBEITEN!</p>')
  end

  specify 'set and validate always active template' do
    template = MailTemplate.create!(title: 'invoice_created')
    expect(template).to be_active

    template.active = false
    expect(template).not_to have_valid(:active)
  end

  specify 'validate liquid syntax' do
    template.subject = 'Bienvenue! {{'
    expect(template).not_to have_valid(:subject_fr)
    template.content = 'Hello {% foo %}'
    expect(template).not_to have_valid(:content_fr)
  end

  specify 'validate subject and content presence' do
    template.subject = ''
    expect(template).not_to have_valid(:subject_fr)
    template.content = ''
    expect(template).not_to have_valid(:content_fr)
  end

  specify 'validate content HTML syntax' do
    template.content = '<p>Hello<//p>'
    expect(template).not_to have_valid(:content_fr)
  end

  specify 'all defaults templates are valid' do
    Current.acp.update! languages: ACP.languages
    MailTemplate.create_all!
    MailTemplate.find_each do |template|
      expect(template).to be_valid
    end
  end
end
