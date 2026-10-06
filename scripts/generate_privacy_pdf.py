import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

def generate_pdf(output_path):
    dirname = os.path.dirname(output_path)
    if dirname:
        os.makedirs(dirname, exist_ok=True)
    
    font_dir = "assets/fonts"
    pdfmetrics.registerFont(TTFont('Inter', os.path.join(font_dir, 'Inter-Regular.ttf')))
    pdfmetrics.registerFont(TTFont('Inter-Medium', os.path.join(font_dir, 'Inter-Medium.ttf')))
    pdfmetrics.registerFont(TTFont('Inter-SemiBold', os.path.join(font_dir, 'Inter-SemiBold.ttf')))
    pdfmetrics.registerFont(TTFont('Inter-Bold', os.path.join(font_dir, 'Inter-Bold.ttf')))

    # A4 is 595.27 x 841.89 points
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=32,
        bottomMargin=32
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Inter-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=3
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Inter-SemiBold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#2563EB'),
        spaceAfter=6
    )

    meta_style = ParagraphStyle(
        'DocMeta',
        parent=styles['Normal'],
        fontName='Inter-Medium',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor('#64748B'),
        spaceAfter=8
    )

    summary_style = ParagraphStyle(
        'SummaryText',
        parent=styles['Normal'],
        fontName='Inter',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor('#334155')
    )

    h2_style = ParagraphStyle(
        'Heading2Custom',
        parent=styles['Normal'],
        fontName='Inter-Bold',
        fontSize=10,
        leading=13,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=7,
        spaceAfter=2
    )

    body_style = ParagraphStyle(
        'BodyCustom',
        parent=styles['Normal'],
        fontName='Inter',
        fontSize=8.5,
        leading=11.8,
        textColor=colors.HexColor('#334155'),
        spaceAfter=2
    )

    bullet_style = ParagraphStyle(
        'BulletCustom',
        parent=styles['Normal'],
        fontName='Inter',
        fontSize=8.5,
        leading=11.5,
        textColor=colors.HexColor('#334155'),
        leftIndent=12,
        spaceAfter=1.5
    )

    alert_style = ParagraphStyle(
        'AlertCustom',
        parent=styles['Normal'],
        fontName='Inter-SemiBold',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor('#991B1B')
    )

    story = []

    # Title & Subtitle
    story.append(Paragraph("Политика конфиденциальности", title_style))
    story.append(Paragraph("Мобильное приложение EKBKG", subtitle_style))
    story.append(Paragraph("<b>Разработчик:</b> Алтынбек Абдираманов &nbsp;•&nbsp; <b>Дата вступления в силу:</b> 20 июня 2026 г.", meta_style))
    story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor('#E2E8F0'), spaceAfter=7))

    # Summary Box
    summary_html = """<b>Краткое резюме:</b><br/>
Политика конфиденциальности приложения EKBKG регламентирует сбор личных данных (имя, контакты, город и фотографии) для регистрации, публикации объявлений и коммуникации между пользователями.<br/>
Данные надёжно хранятся на серверах Supabase (инфраструктура AWS) и не передаются третьим лицам без согласия. Пользователь имеет право удалить аккаунт (в приложении или по запросу до 30 дней), запросить копию данных или отказаться от сервиса.<br/>
<b>Контакты поддержки:</b> suyun.46.kg@gmail.com
"""
    summary_p = Paragraph(summary_html, summary_style)
    summary_table = Table([[summary_p]], colWidths=[doc.width])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#F8FAFC')),
        ('BOX', (0, 0), (-1, -1), 0.8, colors.HexColor('#CBD5E1')),
        ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 4))

    # Section 1
    story.append(Paragraph("1. Общие положения", h2_style))
    story.append(Paragraph(
        "Настоящая Политика конфиденциальности описывает, как мобильное приложение EKBKG "
        "собирает, использует и защищает персональные данные пользователей при использовании сервиса.",
        body_style
    ))

    # Section 2
    story.append(Paragraph("2. Какие данные мы собираем", h2_style))
    story.append(Paragraph("Приложение может обрабатывать следующие категории данных:", body_style))
    story.append(Paragraph("• <b>Имя и фамилия:</b> для персонализации профиля и идентификации автора объявлений.", bullet_style))
    story.append(Paragraph("• <b>Номер телефона:</b> для авторизации в приложении и связи между покупателями и продавцами.", bullet_style))
    story.append(Paragraph("• <b>Адрес электронной почты:</b> для сервисных уведомлений и восстановления доступа.", bullet_style))
    story.append(Paragraph("• <b>Местоположение (город / район):</b> указывается пользователем вручную для фильтрации объявлений (постоянный сбор GPS-координат не ведётся).", bullet_style))
    story.append(Paragraph("• <b>Фотографии:</b> загружаются пользователем исключительно для иллюстрации создаваемых объявлений.", bullet_style))

    # Section 3
    story.append(Paragraph("3. Как мы используем данные", h2_style))
    story.append(Paragraph("Собранные данные используются исключительно в целях:", body_style))
    story.append(Paragraph("• Регистрации, авторизации и управления профилем пользователя.", bullet_style))
    story.append(Paragraph("• Размещения, редактирования и корректного отображения объявлений.", bullet_style))
    story.append(Paragraph("• Обеспечения прямой связи между покупателем и продавцом.", bullet_style))
    story.append(Paragraph("• Обеспечения безопасности сообщества и модерации контента.", bullet_style))
    story.append(Paragraph("• Технической поддержки и улучшения работы мобильного приложения.", bullet_style))

    # Section 4
    story.append(Paragraph("4. Хранение и защита данных", h2_style))
    story.append(Paragraph(
        "Данные хранятся в защищённой облачной базе данных Supabase на серверах Amazon Web Services (AWS) "
        "с применением современных методов шифрования, защищённых протоколов передачи (HTTPS/TLS) и строгих политик доступа (Row Level Security).",
        body_style
    ))

    # Section 5
    story.append(Paragraph("5. Передача данных третьим лицам", h2_style))
    story.append(Paragraph(
        "Мы не продаём, не сдаём в аренду и не передаём персональные данные пользователей третьим лицам "
        "в коммерческих или маркетинговых целях. Передача возможна исключительно в случаях, прямо предусмотренных законодательством.",
        body_style
    ))

    # Section 6
    story.append(Paragraph("6. Права пользователя и удаление аккаунта", h2_style))
    story.append(Paragraph("Каждый пользователь имеет право в любое время:", body_style))
    story.append(Paragraph(
        "• <b>Удалить свой аккаунт:</b> в приложении (<i>Профиль → Удалить аккаунт</i>), либо отправив запрос на <b>suyun.46.kg@gmail.com</b> "
        "с указанием привязанного номера телефона или email (обработка до 30 дней с полным удалением данных).",
        bullet_style
    ))
    story.append(Paragraph("• <b>Запросить копию данных:</b> обратившись в службу поддержки.", bullet_style))
    story.append(Paragraph("• <b>Отказаться от использования сервиса:</b> и прекратить предоставление данных.", bullet_style))

    # Section 7
    story.append(Paragraph("7. Контакты службы поддержки", h2_style))
    story.append(Paragraph(
        "По всем вопросам Политики конфиденциальности или обработки персональных данных: <b>suyun.46.kg@gmail.com</b>.",
        body_style
    ))

    # Section 8: UGC / EULA
    story.append(Paragraph("8. Правила сообщества и нулевая терпимость (EULA)", h2_style))
    alert_text = (
        "Мы придерживаемся политики нулевой терпимости к неприемлемому контенту и оскорбительным действиям "
        "(There is no tolerance for objectionable content or abusive users). "
        "Любой неприемлемый контент, спам, мошенничество или пользователи, нарушающие правила, "
        "будут немедленно заблокированы, а их публикации удалены."
    )
    alert_p = Paragraph(alert_text, alert_style)
    alert_table = Table([[alert_p]], colWidths=[doc.width])
    alert_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#FEF2F2')),
        ('BOX', (0, 0), (-1, -1), 0.8, colors.HexColor('#FECACA')),
        ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 7),
        ('RIGHTPADDING', (0, 0), (-1, -1), 7),
    ]))
    story.append(alert_table)

    doc.build(story)
    print(f"PDF successfully generated at: {output_path}")

if __name__ == "__main__":
    generate_pdf("assets/pdfs/privacy_policy.pdf")
    generate_pdf("docs/privacy_policy.pdf")
    generate_pdf("privacy_policy.pdf")
