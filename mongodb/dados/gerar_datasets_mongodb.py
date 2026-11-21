import glob
import hashlib
import json
import os
import random
import re
import datetime as dt
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
PASTA_SQL = RAIZ / 'mysql' / 'dml'
PASTA_DATASETS = RAIZ / 'mongodb' / 'datasets'
PASTA_AMOSTRAS = RAIZ / 'mongodb' / 'dados' / 'amostras'
FUSO_BRASILIA = dt.timedelta(hours=3)
META_TELEMETRIA = 75000
R = random.Random(2026)


def ler_inserts(pasta):
    tabelas = {}
    padrao = re.compile(r'insert into (\w+) \(([^)]*)\) values\s*', re.I)
    for arquivo in sorted(glob.glob(str(pasta / '[0-9][0-9]_*.sql'))):
        txt = open(arquivo, encoding='utf-8').read()
        for m in padrao.finditer(txt):
            tabela = m.group(1)
            colunas = [c.strip() for c in m.group(2).split(',')]
            i = m.end()
            linhas = tabelas.setdefault(tabela, [])
            while True:
                while txt[i] in ' \r\n\t,':
                    i += 1
                if txt[i] == ';':
                    break
                i += 1
                valores = []
                while True:
                    while txt[i] in ' \r\n\t':
                        i += 1
                    if txt[i] == "'":
                        j = i + 1
                        buf = []
                        while True:
                            if txt[j] == "'":
                                if txt[j + 1] == "'":
                                    buf.append("'")
                                    j += 2
                                    continue
                                break
                            if txt[j] == '\\':
                                buf.append(txt[j + 1])
                                j += 2
                                continue
                            buf.append(txt[j])
                            j += 1
                        valores.append(''.join(buf))
                        i = j + 1
                    else:
                        j = i
                        while txt[j] not in ',)':
                            j += 1
                        tok = txt[i:j].strip()
                        if tok.lower() == 'null':
                            valores.append(None)
                        elif '.' in tok:
                            valores.append(float(tok))
                        else:
                            valores.append(int(tok))
                        i = j
                    while txt[i] in ' \r\n\t':
                        i += 1
                    if txt[i] == ',':
                        i += 1
                        continue
                    i += 1
                    break
                linhas.append(dict(zip(colunas, valores)))
    return tabelas


def hora(texto):
    if texto is None:
        return None
    if len(texto) == 10:
        texto += ' 00:00:00'
    return dt.datetime.strptime(texto, '%Y-%m-%d %H:%M:%S')


def iso(momento):
    return (momento + FUSO_BRASILIA).strftime('%Y-%m-%dT%H:%M:%SZ')


def data_mongo(momento):
    return None if momento is None else {'$date': iso(momento)}


def por_id(linhas, chave):
    return {l[chave]: l for l in linhas}


def agrupar(linhas, chave):
    grupos = {}
    for l in linhas:
        grupos.setdefault(l[chave], []).append(l)
    return grupos


T = ler_inserts(PASTA_SQL)

setores = por_id(T['setor'], 'id_setor')
cargos = por_id(T['cargo'], 'id_cargo')
funcionarios = por_id(T['funcionario'], 'id_funcionario')
pacientes = por_id(T['paciente'], 'id_paciente')
provisorios = por_id(T['cadastro_provisorio'], 'id_cadastro_provisorio')
locais = por_id(T['local'], 'id_local')
equipamentos = por_id(T['equipamento'], 'id_equipamento')
leitos = por_id(T['leito'], 'id_leito')
status_at = por_id(T['status_atendimento'], 'id_status')
classificacoes = por_id(T['classificacao_risco'], 'id_classificacao')
exames = por_id(T['exame'], 'id_exame')
procedimentos = por_id(T['procedimento'], 'id_procedimento')
insumos = por_id(T['insumo'], 'id_insumo')
historicos = {h['id_paciente']: h for h in T['historico_clinico']}
alergias = agrupar(T['alergia'], 'id_historico')
atendimentos = sorted(T['atendimento'], key=lambda a: a['id_atendimento'])
triagens = {t['id_atendimento']: t for t in T['triagem']}
sinais = agrupar(T['sinais_vitais'], 'id_atendimento')
solicitacoes = agrupar(T['solicitacao'], 'id_atendimento')
sol_por_id = por_id(T['solicitacao'], 'id_solicitacao')
resultados = {}
for r in T['resultado_exame']:
    resultados.setdefault(sol_por_id[r['id_solicitacao']]['id_atendimento'], []).append(r)
internacoes = {i['id_atendimento']: i for i in T['internacao']}
ocupacoes = agrupar(T['ocupacao'], 'id_internacao')
transferencias = agrupar(T['transferencia'], 'id_internacao')
altas = {a['id_atendimento']: a for a in T['alta']}

for lista in sinais.values():
    lista.sort(key=lambda s: s['data_hora'])
for lista in solicitacoes.values():
    lista.sort(key=lambda s: s['data_hora'])

AGORA = max(hora(x) for x in
            [a['data_hora_entrada'] for a in atendimentos] + [s['data_hora'] for s in T['sinais_vitais']] +
            [r['data_hora_resultado'] for r in T['resultado_exame']] + [a['data_hora'] for a in T['alta']])

LOCAL_NOME = {l['nome']: l for l in locais.values()}
SALA_VERMELHA = LOCAL_NOME['Sala vermelha (emergência)']['id_local']
SALA_AMARELA = LOCAL_NOME['Sala amarela (emergência)']['id_local']
OBS_ADULTO = LOCAL_NOME['Observação adulto']['id_local']
OBS_PED = LOCAL_NOME['Observação pediátrica']['id_local']
MODELOS = {'Monitor multiparamétrico': 'Monitor multiparamétrico MP-12',
           'Monitor de sinais vitais': 'Monitor de sinais vitais SV-8',
           'Oxímetro de pulso': 'Oxímetro de pulso OX-3'}


def info_funcionario(id_f):
    f = funcionarios[id_f]
    c = cargos[f['id_cargo']]
    return {'id_funcionario': id_f, 'login': f['login'], 'cargo': c['nome'], 'setor': setores[c['id_setor']]['nome']}


def idade(at):
    if at['id_paciente']:
        n = hora(pacientes[at['id_paciente']]['data_nasc'])
        e = hora(at['data_hora_entrada'])
        return e.year - n.year - ((e.month, e.day) < (n.month, n.day))
    return provisorios[at['id_cadastro_provisorio']]['idade_aparente'] or 40


def paciente_ref(at, com_flag=True):
    ref = {'id_paciente': at['id_paciente'], 'id_cadastro_provisorio': at['id_cadastro_provisorio']}
    if com_flag:
        ref['identificado'] = at['id_paciente'] is not None
    return ref


def fim_atendimento(at):
    a = altas.get(at['id_atendimento'])
    if a:
        return hora(a['data_hora'])
    i = internacoes.get(at['id_atendimento'])
    if i and i['data_hora_saida']:
        return hora(i['data_hora_saida'])
    return AGORA


def equipe(at):
    medicos, enfermagem = [], []
    for s in solicitacoes.get(at['id_atendimento'], []):
        medicos.append((hora(s['data_hora']), s['id_funcionario']))
    i = internacoes.get(at['id_atendimento'])
    if i:
        medicos.append((hora(i['data_hora_entrada']), i['id_funcionario']))
        for t in transferencias.get(i['id_internacao'], []):
            medicos.append((hora(t['data_hora']), t['id_funcionario']))
    a = altas.get(at['id_atendimento'])
    if a:
        medicos.append((hora(a['data_hora']), a['id_funcionario']))
    t = triagens.get(at['id_atendimento'])
    if t:
        enfermagem.append((hora(t['data_hora']), t['id_funcionario']))
    for s in sinais.get(at['id_atendimento'], []):
        enfermagem.append((hora(s['data_hora']), s['id_funcionario']))
    return sorted(medicos), sorted(enfermagem)


def mais_proximo(lista, momento):
    if not lista:
        return None
    return min(lista, key=lambda x: abs((x[0] - momento).total_seconds()))[1]


def dispositivos_do_local(id_local):
    return [e for e in equipamentos.values() if e['id_local'] == id_local and e['status'] != 'I'
            and any(e['nome'].startswith(m) for m in MODELOS)]


ocupado = {}


def reservar(id_local, inicio, fim, preferido=None):
    candidatos = dispositivos_do_local(id_local)
    candidatos.sort(key=lambda e: (e['id_equipamento'] != preferido, not e['nome'].startswith('Monitor')))
    for e in candidatos:
        intervalos = ocupado.setdefault(e['id_equipamento'], [])
        if all(not (inicio < b and a < fim) for a, b in intervalos):
            intervalos.append((inicio, fim))
            return e
    return None


segmentos = {}
for at in atendimentos:
    aid = at['id_atendimento']
    segs = []
    tri = triagens.get(aid)
    inter = internacoes.get(aid)
    fim = fim_atendimento(at)
    ped = idade(at) < 12
    if tri:
        cor = classificacoes[tri['id_classificacao']]['prioridade']
        local_ps = None
        if cor == 1:
            local_ps = SALA_VERMELHA
        elif cor == 2:
            local_ps = OBS_PED if ped else SALA_AMARELA
        elif inter or at['id_local'] in (OBS_ADULTO, OBS_PED):
            local_ps = OBS_PED if ped else OBS_ADULTO
        if local_ps:
            ini = hora(tri['data_hora']) + dt.timedelta(minutes=R.randint(8, 20))
            fim_ps = fim
            if inter:
                ocs = ocupacoes.get(inter['id_internacao'], [])
                fim_ps = min([hora(o['data_hora_entrada']) for o in ocs] or [hora(inter['data_hora_entrada'])])
            if fim_ps - ini > dt.timedelta(minutes=20):
                segs.append({'tipo': 'PS', 'id_local': local_ps, 'id_leito': None, 'inicio': ini, 'fim': fim_ps})
    if inter:
        for o in sorted(ocupacoes.get(inter['id_internacao'], []), key=lambda o: o['data_hora_entrada']):
            lt = leitos[o['id_leito']]
            ini = hora(o['data_hora_entrada'])
            fim_o = hora(o['data_hora_saida']) if o['data_hora_saida'] else AGORA
            tipo = 'UTI' if locais[lt['id_local']]['tipo'] == 'U' else 'ENFERMARIA'
            segs.append({'tipo': tipo, 'id_local': lt['id_local'], 'id_leito': lt['id_leito'], 'inicio': ini, 'fim': fim_o})
    segmentos[aid] = segs

todos_segs = sorted(((aid, s) for aid, ss in segmentos.items() for s in ss), key=lambda x: x[1]['inicio'])
for aid, s in todos_segs:
    preferido = None
    if s['tipo'] == 'UTI':
        mons = sorted([e for e in dispositivos_do_local(s['id_local']) if e['nome'].startswith('Monitor')],
                      key=lambda e: e['id_equipamento'])
        leitos_local = sorted([l['id_leito'] for l in leitos.values() if l['id_local'] == s['id_local']])
        k = leitos_local.index(s['id_leito'])
        if k < len(mons):
            preferido = mons[k]['id_equipamento']
    s['dispositivo'] = reservar(s['id_local'], s['inicio'], s['fim'], preferido)

PESO_INTERVALO = {'UTI': 1.0, 'PS': 0.6, 'ENFERMARIA': 3.0}
minutos = {k: 0.0 for k in PESO_INTERVALO}
for aid, s in todos_segs:
    if s['dispositivo']:
        minutos[s['tipo']] += (s['fim'] - s['inicio']).total_seconds() / 60
base = sum(minutos[k] / PESO_INTERVALO[k] for k in minutos) / META_TELEMETRIA
INTERVALO = {k: base * PESO_INTERVALO[k] for k in PESO_INTERVALO}

CATEGORIAS = {
    'RESPIRATORIA': {
        'descricoes': ['Queda súbita de saturação de O2 para {sat}% com desconforto respiratório.',
                       'Dispneia intensa com uso de musculatura acessória e saturação de {sat}%.'],
        'medidas': ['Oferta de oxigênio por máscara não reinalante a 10 L/min', 'Elevação da cabeceira a 45 graus',
                    'Solicitação de gasometria arterial de urgência', 'Nebulização com broncodilatador',
                    'Avaliação médica imediata à beira do leito'],
        'gravidade': {'MEDIA': 3, 'ALTA': 4, 'CRITICA': 2}, 'tags': ['hipoxemia', 'oxigenoterapia'], 'efeito': 'sat'},
    'CARDIOVASCULAR': {
        'descricoes': ['Taquicardia de {fc} bpm com palpitação e mal-estar.',
                       'Dor torácica em aperto com frequência cardíaca de {fc} bpm.'],
        'medidas': ['Monitorização cardíaca contínua', 'Eletrocardiograma de 12 derivações',
                    'Avaliação médica imediata à beira do leito', 'Acesso venoso calibroso'],
        'gravidade': {'MEDIA': 3, 'ALTA': 4, 'CRITICA': 2}, 'tags': ['taquicardia', 'monitorizacao'], 'efeito': 'fc'},
    'HEMODINAMICA': {
        'descricoes': ['Hipotensão de {pas}x{pad} mmHg com sudorese e palidez.',
                       'Queda da pressão arterial para {pas}x{pad} mmHg e sonolência.'],
        'medidas': ['Expansão volêmica com SF 0,9% 500 mL', 'Elevação dos membros inferiores',
                    'Início de noradrenalina em bomba de infusão', 'Coleta de lactato arterial'],
        'gravidade': {'MEDIA': 2, 'ALTA': 4, 'CRITICA': 3}, 'tags': ['hipotensao', 'instabilidade_hemodinamica'], 'efeito': 'pas'},
    'NEUROLOGICA': {
        'descricoes': ['Rebaixamento do nível de consciência (Glasgow {glasgow}).',
                       'Crise convulsiva tônico-clônica com duração aproximada de {min} minutos.'],
        'medidas': ['Proteção das vias aéreas e lateralização', 'Glicemia capilar', 'Diazepam 10 mg EV conforme prescrição',
                    'Avaliação neurológica pelo médico plantonista'],
        'gravidade': {'MEDIA': 2, 'ALTA': 4, 'CRITICA': 2}, 'tags': ['neurologico'], 'efeito': 'sat'},
    'METABOLICA': {
        'descricoes': ['Glicemia capilar de {glic} mg/dL com sudorese e tremores.',
                       'Hiperglicemia de {glic_alta} mg/dL mesmo após insulina.'],
        'medidas': ['Glicemia capilar de controle', 'Glicose 50% 30 mL EV', 'Ajuste da insulinoterapia conforme protocolo'],
        'gravidade': {'BAIXA': 2, 'MEDIA': 4, 'ALTA': 2}, 'tags': ['glicemia'], 'efeito': None},
    'HEMORRAGICA': {
        'descricoes': ['Novo episódio de hematêmese com cerca de {ml} mL.', 'Sangramento ativo em sítio de punção venosa.'],
        'medidas': ['Compressão local', 'Coleta de hemograma de controle', 'Avaliação médica imediata', 'Reserva de hemocomponentes'],
        'gravidade': {'MEDIA': 3, 'ALTA': 3, 'CRITICA': 1}, 'tags': ['sangramento'], 'efeito': 'fc'},
    'FEBRE': {
        'descricoes': ['Pico febril de {temp} °C com calafrios.'],
        'medidas': ['Antitérmico conforme prescrição', 'Coleta de hemoculturas', 'Compressas frias'],
        'gravidade': {'BAIXA': 5, 'MEDIA': 3}, 'tags': ['febre'], 'efeito': 'temp'},
    'QUEDA': {
        'descricoes': ['Queda da maca ao tentar ir ao banheiro sem acompanhante, sem perda de consciência.',
                       'Queda da própria altura no corredor durante deambulação.'],
        'medidas': ['Avaliação de lesões pelo médico', 'Grades do leito elevadas', 'Orientação ao acompanhante',
                    'Notificação ao núcleo de segurança do paciente'],
        'gravidade': {'BAIXA': 5, 'MEDIA': 2}, 'tags': ['queda', 'seguranca_paciente'], 'efeito': None},
    'REACAO_MEDICAMENTO': {
        'descricoes': ['Prurido e placas urticariformes após administração de {insumo}.'],
        'medidas': ['Suspensão imediata da medicação', 'Prometazina 25 mg IM', 'Observação clínica por 1 hora após a reação'],
        'gravidade': {'BAIXA': 2, 'MEDIA': 3, 'ALTA': 1}, 'tags': ['reacao_adversa', 'farmacovigilancia'], 'efeito': 'fc'},
    'ACESSO_VENOSO': {
        'descricoes': ['Perda do acesso venoso periférico com infiltração no antebraço.'],
        'medidas': ['Retirada do cateter', 'Nova punção em membro contralateral', 'Compressa fria no local'],
        'gravidade': {'BAIXA': 6, 'MEDIA': 1}, 'tags': ['acesso_venoso'], 'efeito': None},
    'AGITACAO': {
        'descricoes': ['Agitação psicomotora com tentativa de retirar dispositivos.'],
        'medidas': ['Abordagem verbal e redução de estímulos', 'Haloperidol 5 mg IM conforme prescrição',
                    'Contenção mecânica temporária conforme protocolo'],
        'gravidade': {'BAIXA': 2, 'MEDIA': 3, 'ALTA': 1}, 'tags': ['agitacao'], 'efeito': 'fc'},
    'DOR': {
        'descricoes': ['Dor intensa (EVA {eva}/10) refratária à analgesia inicial.'],
        'medidas': ['Reavaliação da dor', 'Analgesia de resgate conforme prescrição', 'Comunicação ao médico'],
        'gravidade': {'BAIXA': 3, 'MEDIA': 3}, 'tags': ['dor'], 'efeito': 'fc'},
}
CID_CATEGORIAS = [
    (('I21', 'I50', 'I10', 'R07'), {'CARDIOVASCULAR': 5, 'HEMODINAMICA': 2, 'RESPIRATORIA': 2, 'DOR': 1}),
    (('J18', 'J44', 'J45', 'J21', 'J11', 'U07'), {'RESPIRATORIA': 6, 'FEBRE': 3, 'CARDIOVASCULAR': 1}),
    (('I63', 'I61', 'G40', 'R56', 'S06', 'F10', 'T42'), {'NEUROLOGICA': 5, 'AGITACAO': 3, 'RESPIRATORIA': 1}),
    (('A41', 'N10'), {'HEMODINAMICA': 5, 'FEBRE': 3, 'RESPIRATORIA': 2}),
    (('K92',), {'HEMORRAGICA': 5, 'HEMODINAMICA': 3}),
    (('E16', 'E10', 'R73'), {'METABOLICA': 6, 'NEUROLOGICA': 1}),
    (('T07', 'S72', 'S52', 'S42'), {'DOR': 4, 'HEMODINAMICA': 2, 'HEMORRAGICA': 1, 'AGITACAO': 1}),
    (('A90', 'A91'), {'HEMORRAGICA': 3, 'HEMODINAMICA': 2, 'FEBRE': 3}),
    (('T78', 'L50', 'T88'), {'REACAO_MEDICAMENTO': 3, 'RESPIRATORIA': 3, 'HEMODINAMICA': 2}),
]
GERAIS = {'QUEDA': 3, 'ACESSO_VENOSO': 4, 'DOR': 3, 'FEBRE': 2, 'AGITACAO': 1, 'REACAO_MEDICAMENTO': 1}


def sortear(pesos):
    itens = list(pesos.items())
    x = R.uniform(0, sum(p for _, p in itens))
    for k, p in itens:
        x -= p
        if x <= 0:
            return k
    return itens[-1][0]


def categoria_do_atendimento(at):
    a = altas.get(at['id_atendimento'])
    cid = (a or {}).get('cid_final') or ''
    pesos = dict(GERAIS)
    for prefixos, extra in CID_CATEGORIAS:
        if cid.startswith(prefixos):
            for k, v in extra.items():
                pesos[k] = pesos.get(k, 0) + v * 3
    return sortear(pesos)


def segmento_em(aid, momento):
    for s in segmentos[aid]:
        if s['inicio'] <= momento <= s['fim']:
            return s
    return None


def alergico_dipirona(at):
    h = historicos.get(at['id_paciente'])
    return bool(h) and any(a['agente'] == 'Dipirona' for a in alergias.get(h['id_historico'], []))


intercorrencias = []
for at in atendimentos:
    aid = at['id_atendimento']
    tri = triagens.get(aid)
    if not tri:
        continue
    inicio = hora(tri['data_hora'])
    fim = fim_atendimento(at)
    if fim <= inicio + dt.timedelta(minutes=30):
        continue
    cor = classificacoes[tri['id_classificacao']]['prioridade']
    quantidade = 0
    if R.random() < {1: .7, 2: .45, 3: .12, 4: .02, 5: .005}[cor]:
        quantidade += 1 if R.random() < .75 else 2
    inter = internacoes.get(aid)
    if inter:
        for s in segmentos[aid]:
            dias = (s['fim'] - s['inicio']).total_seconds() / 86400
            taxa = {'UTI': 1.1, 'ENFERMARIA': .35, 'PS': 0}[s['tipo']]
            esperado = dias * taxa
            quantidade += int(esperado) + (1 if R.random() < esperado - int(esperado) else 0)
    medicos, enfermagem = equipe(at)
    insumos_dados = [insumos[s['id_insumo']]['nome'] for s in solicitacoes.get(aid, [])
                     if s['tipo'] == 'I' and s['status'] == 'R' and insumos[s['id_insumo']]['tipo'] == 'M']
    for _ in range(quantidade):
        momento = inicio + dt.timedelta(seconds=R.uniform(15 * 60, (fim - inicio).total_seconds() - 10 * 60))
        momento = momento.replace(microsecond=0)
        cat = categoria_do_atendimento(at)
        if cat == 'REACAO_MEDICAMENTO' and not insumos_dados:
            cat = 'ACESSO_VENOSO'
        c = CATEGORIAS[cat]
        grav = sortear(c['gravidade'])
        if cor >= 4 and grav == 'CRITICA':
            grav = 'ALTA'
        valores = {'sat': R.randint(82, 89) if grav in ('ALTA', 'CRITICA') else R.randint(88, 91),
                   'fc': R.randint(132, 168) if grav in ('ALTA', 'CRITICA') else R.randint(112, 130),
                   'pas': R.randint(68, 84) if grav in ('ALTA', 'CRITICA') else R.randint(85, 92),
                   'temp': round(R.uniform(38.6, 40.0) if grav != 'BAIXA' else R.uniform(37.9, 38.5), 1),
                   'glasgow': R.randint(8, 12), 'min': R.randint(2, 6), 'glic': R.randint(32, 58),
                   'glic_alta': R.randint(380, 560), 'ml': R.choice([100, 150, 200, 300]), 'eva': R.randint(8, 10)}
        valores['pad'] = valores['pas'] - R.randint(28, 38)
        valores['insumo'] = R.choice(insumos_dados).split(' ')[0] if insumos_dados else ''
        descricao = R.choice(c['descricoes']).format(**valores)
        seg = segmento_em(aid, momento)
        id_local = seg['id_local'] if seg else at['id_local']
        if cat in ('QUEDA', 'ACESSO_VENOSO', 'DOR', 'FEBRE', 'AGITACAO') or not medicos:
            id_resp = mais_proximo(enfermagem, momento) or mais_proximo(medicos, momento)
        else:
            id_resp = mais_proximo(medicos, momento)
        n_medidas = min(len(c['medidas']), R.randint(2, 4))
        medidas = []
        t_medida = momento
        for ordem, acao in enumerate(c['medidas'][:n_medidas], 1):
            if acao.startswith('Antitérmico') and alergico_dipirona(at):
                acao = 'Paracetamol 750 mg VO (paciente alérgico à dipirona)'
            t_medida = t_medida + dt.timedelta(seconds=R.randint(30, 360))
            executor = mais_proximo(enfermagem, t_medida) or id_resp
            if acao.startswith(('Avaliação', 'Início de noradrenalina', 'Solicitação', 'Reserva')):
                executor = mais_proximo(medicos, t_medida) or executor
            medidas.append({'ordem': ordem, 'acao': acao, 'hora': data_mongo(t_medida),
                            'executado_por_id_funcionario': executor})
        idade_h = (AGORA - momento).total_seconds() / 3600
        aberto = fim == AGORA and aid not in altas
        if aberto and idade_h < 3:
            status = 'ABERTA'
        elif aberto and idade_h < 48:
            status = 'EM_ACOMPANHAMENTO'
        else:
            status = 'RESOLVIDA'
        resolvida_em = None
        if status == 'RESOLVIDA':
            resolvida_em = min(fim, t_medida + dt.timedelta(minutes=R.randint(20, 240)))
        tags = list(c['tags'])
        if seg and seg['tipo'] == 'UTI':
            tags.append('uti')
        if at['id_paciente'] is None:
            tags.append('paciente_nao_identificado')
        intercorrencias.append({
            '_momento': momento, '_cat': cat, '_grav': grav, '_valores': valores, 'id_atendimento': aid,
            'id_paciente': at['id_paciente'], 'id_cadastro_provisorio': at['id_cadastro_provisorio'], 'id_local': id_local,
            'data_hora': data_mongo(momento), 'categoria': cat, 'gravidade': grav, 'status': status,
            'descricao': descricao, 'responsavel': {k: v for k, v in info_funcionario(id_resp).items() if k != 'setor'},
            'medidas_adotadas': medidas, 'data_hora_resolucao': data_mongo(resolvida_em), 'tags': tags})

intercorrencias.sort(key=lambda x: x['_momento'])
for n, doc in enumerate(intercorrencias, 1):
    doc['codigo_intercorrencia'] = f'INT-{doc["_momento"].year}-{n:06d}'
int_por_at = agrupar(intercorrencias, 'id_atendimento')

LIMITES = [(1, 180, 60, 65), (6, 150, 40, 75), (12, 130, 30, 85), (200, 100, 24, 90)]


def limites(anos):
    for ate, fc, fr, pas in LIMITES:
        if anos < ate:
            return fc, fr, pas


def alertas(sv, anos):
    lim_fc, lim_fr, lim_pas = limites(anos)
    saida = []
    sat, fc, fr, temp = sv['saturacao_o2_pct'], sv['frequencia_cardiaca_bpm'], sv['frequencia_respiratoria_irpm'], sv['temperatura_c']
    pas = sv['pressao_arterial']['sistolica_mmhg'] if sv['pressao_arterial'] else None
    if sat is not None and sat < 92:
        sev = 'CRITICA' if sat < 85 else 'ALTA' if sat < 88 else 'MEDIA' if sat < 90 else 'BAIXA'
        saida.append({'codigo': 'HIPOXEMIA', 'severidade': sev, 'valor_medido': sat, 'limite_referencia': 92})
    if fc > lim_fc:
        sev = 'CRITICA' if fc > lim_fc + 50 else 'ALTA' if fc > lim_fc + 30 else 'MEDIA' if fc > lim_fc + 15 else 'BAIXA'
        saida.append({'codigo': 'TAQUICARDIA', 'severidade': sev, 'valor_medido': fc, 'limite_referencia': lim_fc})
    if fc < 50 and anos >= 12:
        saida.append({'codigo': 'BRADICARDIA', 'severidade': 'CRITICA' if fc < 40 else 'ALTA', 'valor_medido': fc,
                      'limite_referencia': 50})
    if pas is not None and pas < lim_pas:
        sev = 'CRITICA' if pas < lim_pas - 15 else 'ALTA' if pas < lim_pas - 10 else 'MEDIA'
        saida.append({'codigo': 'HIPOTENSAO', 'severidade': sev, 'valor_medido': pas, 'limite_referencia': lim_pas})
    if pas is not None and pas > 180:
        saida.append({'codigo': 'HIPERTENSAO', 'severidade': 'ALTA' if pas > 200 else 'MEDIA', 'valor_medido': pas,
                      'limite_referencia': 180})
    if fr > lim_fr:
        saida.append({'codigo': 'TAQUIPNEIA', 'severidade': 'ALTA' if fr > lim_fr + 6 else 'MEDIA', 'valor_medido': fr,
                      'limite_referencia': lim_fr})
    if temp is not None and temp >= 37.8:
        sev = 'ALTA' if temp >= 39.5 else 'MEDIA' if temp >= 38.5 else 'BAIXA'
        saida.append({'codigo': 'FEBRE', 'severidade': sev, 'valor_medido': temp, 'limite_referencia': 37.8})
    return saida


def limitar(v, a, b):
    return max(a, min(b, v))


telemetria = []
for at in atendimentos:
    aid = at['id_atendimento']
    anos = idade(at)
    lista_sv = [(hora(s['data_hora']), s) for s in sinais.get(aid, [])]
    eventos_int = int_por_at.get(aid, [])
    for seg in segmentos[aid]:
        disp = seg['dispositivo']
        if not disp:
            continue
        passo = dt.timedelta(minutes=INTERVALO[seg['tipo']])
        momento = seg['inicio'] + dt.timedelta(seconds=R.uniform(0, passo.total_seconds()))
        bateria = R.randint(80, 100)
        loc = locais[seg['id_local']]
        while momento < seg['fim']:
            antes = [s for t, s in lista_sv if t <= momento]
            ref = antes[-1] if antes else (lista_sv[0][1] if lista_sv else None)
            fc = (ref or {}).get('frequencia_cardiaca') or 85
            fr = (ref or {}).get('frequencia_respiratoria') or 18
            pas = (ref or {}).get('pressao_sistolica')
            pad = (ref or {}).get('pressao_diastolica')
            sat = (ref or {}).get('saturacao_o2') or 96
            temp = float((ref or {}).get('temperatura') or 36.6)
            qualidade = 'OK'
            ruido = 1.0
            sorteio = R.random()
            if sorteio < .025:
                qualidade, ruido = 'INTERFERENCIA', 2.5
            fc = fc + R.gauss(0, 4 * ruido)
            fr = fr + R.gauss(0, 1.5 * ruido)
            sat = sat + R.gauss(0, .8 * ruido)
            temp = temp + R.gauss(0, .15)
            if pas is not None:
                pas = pas + R.gauss(0, 6 * ruido)
                pad = pad + R.gauss(0, 4 * ruido)
            for ev in eventos_int:
                delta = (momento - ev['_momento']).total_seconds() / 60
                if -10 <= delta <= 45:
                    v = ev['_valores']
                    peso = 1.0 if delta <= 20 else max(0.0, 1 - (delta - 20) / 25)
                    efeito = CATEGORIAS[ev['_cat']]['efeito']
                    if efeito == 'sat':
                        sat = sat * (1 - peso) + v['sat'] * peso
                        fr = fr * (1 - peso) + R.randint(26, 34) * peso
                    elif efeito == 'fc':
                        fc = fc * (1 - peso) + v['fc'] * peso
                    elif efeito == 'pas' and pas is not None:
                        pas = pas * (1 - peso) + v['pas'] * peso
                        pad = pad * (1 - peso) + v['pad'] * peso
                        fc = fc * (1 - peso) + R.randint(110, 130) * peso
                    elif efeito == 'temp':
                        temp = temp * (1 - peso) + v['temp'] * peso
            sinais_doc = {
                'frequencia_cardiaca_bpm': int(round(limitar(fc, 30, 220))),
                'frequencia_respiratoria_irpm': int(round(limitar(fr, 8, 70))),
                'pressao_arterial': None if pas is None else {
                    'sistolica_mmhg': int(round(limitar(pas, 50, 260))),
                    'diastolica_mmhg': int(round(limitar(min(pad, pas - 15), 25, 160)))},
                'saturacao_o2_pct': int(round(limitar(sat, 70, 100))),
                'temperatura_c': round(limitar(temp, 34.0, 41.5), 1)}
            if sorteio > .99:
                qualidade = 'SEM_SINAL_SPO2'
                sinais_doc['saturacao_o2_pct'] = None
            bateria = max(15, bateria - (1 if R.random() < .02 else 0))
            telemetria.append({
                'id_atendimento': aid,
                'paciente_ref': paciente_ref(at),
                'dispositivo': {'id_equipamento': disp['id_equipamento'], 'numero_patrimonio': disp['numero_patrimonio'],
                                'modelo': next(v for k, v in MODELOS.items() if disp['nome'].startswith(k)),
                                'bateria_pct': bateria},
                'localizacao': {'id_local': loc['id_local'], 'nome_local': loc['nome'], 'tipo_local': loc['tipo'],
                                'id_leito': seg['id_leito'],
                                'numero_leito': leitos[seg['id_leito']]['numero'] if seg['id_leito'] else None},
                'timestamp': data_mongo(momento.replace(microsecond=0)),
                'sinais': sinais_doc,
                'alertas_disparados': alertas(sinais_doc, anos),
                'qualidade_sinal': qualidade,
                '_momento': momento})
            momento += passo * R.uniform(.85, 1.15)
telemetria.sort(key=lambda d: d['_momento'])

ESTACAO = {'Recepção': 'REC', 'Pronto-Socorro': 'PS', 'Enfermagem': 'ENF', 'UTI': 'UTI', 'Internação': 'INT',
           'Laboratório': 'LAB', 'Diagnóstico por Imagem': 'IMG', 'Farmácia': 'FAR', 'Almoxarifado': 'ALM',
           'Administração': 'ADM'}
logs = []


def registrar(momento, id_f, acao, modulo, tabela, registro_id, antes=None, depois=None, tags=None, sucesso=True,
              com_alteracoes=True, extra=None):
    u = info_funcionario(id_f)
    id_setor = cargos[funcionarios[id_f]['id_cargo']]['id_setor']
    doc = {'timestamp': momento.replace(microsecond=0), 'usuario': u, 'acao': acao, 'modulo': modulo,
           'entidade': {'tabela': tabela, 'registro_id': registro_id}}
    if com_alteracoes:
        doc['alteracoes'] = {'antes': antes, 'depois': depois}
    doc['contexto_acesso'] = {'ip': f'10.20.{id_setor}.{10 + id_f % 200}',
                              'estacao': f'{ESTACAO[u["setor"]]}-TERM-{id_f % 15 + 1:02d}', 'sucesso': sucesso}
    if extra:
        doc.update(extra)
    doc['tags'] = tags or []
    logs.append(doc)


segundos = lambda a, b: dt.timedelta(seconds=R.randint(a, b))
for p in T['registro_ponto']:
    t = hora(p['data_hora'])
    if p['tipo'] == 'E':
        if R.random() < .03:
            registrar(t + segundos(60, 200), p['id_funcionario'], 'LOGIN', 'AUTENTICACAO', 'funcionario',
                      p['id_funcionario'], tags=['autenticacao', 'falha_login'], sucesso=False, com_alteracoes=False,
                      extra={'motivo_falha': 'CREDENCIAIS_INVALIDAS'})
        registrar(t + segundos(240, 900), p['id_funcionario'], 'LOGIN', 'AUTENTICACAO', 'funcionario',
                  p['id_funcionario'], tags=['autenticacao'], com_alteracoes=False)
    else:
        registrar(t - segundos(60, 600), p['id_funcionario'], 'LOGOUT', 'AUTENTICACAO', 'funcionario',
                  p['id_funcionario'], tags=['autenticacao'], com_alteracoes=False)

for at in atendimentos:
    aid = at['id_atendimento']
    t0 = hora(at['data_hora_entrada'])
    registrar(t0, at['id_funcionario'], 'INSERT', 'ATENDIMENTO', 'atendimento', aid, None,
              {'id_status': 1, 'tipo_entrada': at['tipo_entrada'], 'id_paciente': at['id_paciente'],
               'id_cadastro_provisorio': at['id_cadastro_provisorio']}, ['abertura_atendimento'])
    if at['id_cadastro_provisorio']:
        pr = provisorios[at['id_cadastro_provisorio']]
        registrar(t0 - segundos(60, 120), at['id_funcionario'], 'INSERT', 'ATENDIMENTO', 'cadastro_provisorio',
                  pr['id_cadastro_provisorio'], None, {'identificacao': pr['identificacao']}, ['paciente_nao_identificado'])
        if pr['data_identificacao']:
            registrar(hora(pr['data_identificacao']), at['id_funcionario'], 'UPDATE', 'ATENDIMENTO', 'cadastro_provisorio',
                      pr['id_cadastro_provisorio'], {'id_paciente': None}, {'id_paciente': pr['id_paciente']},
                      ['identificacao_paciente'])
    tri = triagens.get(aid)
    if tri:
        t = hora(tri['data_hora'])
        registrar(t, tri['id_funcionario'], 'INSERT', 'TRIAGEM', 'triagem', tri['id_triagem'], None,
                  {'id_classificacao': tri['id_classificacao']}, ['triagem', 'classificacao_risco'])
        registrar(t + segundos(5, 40), tri['id_funcionario'], 'UPDATE', 'ATENDIMENTO', 'atendimento', aid,
                  {'id_status': 1}, {'id_status': 2}, ['mudanca_status'])
    sols = solicitacoes.get(aid, [])
    if sols and at['id_paciente'] and at['id_paciente'] in historicos:
        primeira = hora(sols[0]['data_hora'])
        registrar(primeira - segundos(120, 600), sols[0]['id_funcionario'], 'SELECT', 'PRONTUARIO', 'historico_clinico',
                  historicos[at['id_paciente']]['id_historico'], tags=['dado_sensivel', 'lgpd', 'prontuario'],
                  com_alteracoes=False)
    for s in sols:
        if s['tipo'] == 'I':
            continue
        item = {'id_exame': s['id_exame']} if s['tipo'] == 'E' else {'id_procedimento': s['id_procedimento']}
        registrar(hora(s['data_hora']), s['id_funcionario'], 'INSERT', 'SOLICITACOES', 'solicitacao', s['id_solicitacao'],
                  None, dict(tipo=s['tipo'], prioridade=s['prioridade'], **item),
                  ['exame' if s['tipo'] == 'E' else 'procedimento'])
    for r in resultados.get(aid, []):
        registrar(hora(r['data_hora_resultado']), r['id_funcionario'], 'INSERT', 'EXAMES', 'resultado_exame',
                  r['id_resultado'], None, {'id_solicitacao': r['id_solicitacao'], 'situacao': r['situacao']},
                  ['laudo'] + (['resultado_critico'] if r['situacao'] == 'C' else []))
    inter = internacoes.get(aid)
    if inter:
        t = hora(inter['data_hora_entrada'])
        registrar(t, inter['id_funcionario'], 'INSERT', 'INTERNACAO', 'internacao', inter['id_internacao'], None,
                  {'tipo': inter['tipo'], 'status': 'A'}, ['internacao'])
        registrar(t + segundos(10, 60), inter['id_funcionario'], 'UPDATE', 'ATENDIMENTO', 'atendimento', aid,
                  {'id_status': 5}, {'id_status': 6}, ['mudanca_status'])
        for o in ocupacoes.get(inter['id_internacao'], []):
            enf = mais_proximo(equipe(at)[1], hora(o['data_hora_entrada'])) or inter['id_funcionario']
            registrar(hora(o['data_hora_entrada']), enf, 'INSERT', 'LEITOS', 'ocupacao', o['id_ocupacao'], None,
                      {'id_leito': o['id_leito']}, ['leito', 'ocupacao'])
        for tr in transferencias.get(inter['id_internacao'], []):
            registrar(hora(tr['data_hora']), tr['id_funcionario'], 'INSERT', 'INTERNACAO', 'transferencia',
                      tr['id_transferencia'], None, {'tipo': tr['tipo'], 'destino': tr['destino']}, ['transferencia'])
    a = altas.get(aid)
    if a:
        t = hora(a['data_hora'])
        registrar(t, a['id_funcionario'], 'INSERT', 'ALTA', 'alta', a['id_alta'], None,
                  {'tipo': a['tipo'], 'cid_final': a['cid_final']}, ['alta'] + (['obito'] if a['tipo'] == 'O' else []))
        registrar(t + segundos(5, 30), a['id_funcionario'], 'UPDATE', 'ATENDIMENTO', 'atendimento', aid,
                  {'id_status': 6 if inter else 3}, {'id_status': 8}, ['mudanca_status', 'encerramento'])

logs.sort(key=lambda d: d['timestamp'])
hash_anterior = '0' * 64
for d in logs:
    d['timestamp'] = data_mongo(d['timestamp'])
    d['hash_anterior'] = hash_anterior
    d['hash_registro'] = hashlib.sha256((hash_anterior + json.dumps(d, sort_keys=True, ensure_ascii=False)).encode()).hexdigest()
    hash_anterior = d['hash_registro']

TIPO_SOL = {'E': 'EXAME_SOLICITADO', 'P': 'PROCEDIMENTO_SOLICITADO', 'I': 'MEDICACAO_MATERIAL'}
TIPO_ENTRADA = {'E': 'Espontânea', 'A': 'Ambulância/SAMU', 'B': 'Bombeiros/polícia', 'T': 'Transferência'}
TIPO_ALTA = {'M': 'Alta médica', 'P': 'Alta a pedido', 'T': 'Alta por transferência', 'O': 'Óbito', 'E': 'Evasão'}
linha_tempo = []
for at in atendimentos:
    aid = at['id_atendimento']
    ev = []
    t0 = hora(at['data_hora_entrada'])
    ev.append((t0, {'tipo': 'ENTRADA', 'id_funcionario': at['id_funcionario'],
                    'resumo': f'Abertura de atendimento ({TIPO_ENTRADA[at["tipo_entrada"]]}) - Queixa: {at["queixa_principal"]}',
                    'detalhes': {'tipo_entrada': at['tipo_entrada'], 'id_local': at['id_local']}}))
    tri = triagens.get(aid)
    classif = None
    if tri:
        c = classificacoes[tri['id_classificacao']]
        classif = {'cor': c['cor'], 'prioridade': c['prioridade']}
        ev.append((hora(tri['data_hora']), {'tipo': 'TRIAGEM', 'id_funcionario': tri['id_funcionario'],
                                            'resumo': f'Classificação {c["cor"]} ({c["descricao"]})',
                                            'detalhes': {'id_triagem': tri['id_triagem'], 'cor': c['cor']}}))
    for s in sinais.get(aid, []):
        ev.append((hora(s['data_hora']), {'tipo': 'SINAIS_VITAIS', 'id_funcionario': s['id_funcionario'],
                                          'resumo': f'PA {s["pressao_sistolica"] or "-"}x{s["pressao_diastolica"] or "-"}, '
                                                    f'FC {s["frequencia_cardiaca"]}, SpO2 {s["saturacao_o2"]}%',
                                          'detalhes': {'id_sinais_vitais': s['id_sinais_vitais']}}))
    for s in solicitacoes.get(aid, []):
        if s['tipo'] == 'E':
            nome = exames[s['id_exame']]['nome']
        elif s['tipo'] == 'P':
            nome = procedimentos[s['id_procedimento']]['nome']
        else:
            nome = insumos[s['id_insumo']]['nome']
        ev.append((hora(s['data_hora']), {'tipo': TIPO_SOL[s['tipo']], 'id_funcionario': s['id_funcionario'],
                                          'resumo': f'{nome} (quantidade {s["quantidade"]})',
                                          'detalhes': {'id_solicitacao': s['id_solicitacao'], 'status': s['status'],
                                                       'prioridade': s['prioridade']}}))
    for r in resultados.get(aid, []):
        nome = exames[sol_por_id[r['id_solicitacao']]['id_exame']]['nome']
        sit = {'N': 'normal', 'A': 'alterado', 'C': 'crítico'}[r['situacao']]
        ev.append((hora(r['data_hora_resultado']), {'tipo': 'RESULTADO_EXAME', 'id_funcionario': r['id_funcionario'],
                                                    'resumo': f'Laudo de {nome}: {sit}',
                                                    'detalhes': {'id_resultado': r['id_resultado'],
                                                                 'id_solicitacao': r['id_solicitacao'],
                                                                 'situacao': r['situacao']}}))
    inter = internacoes.get(aid)
    if inter:
        ev.append((hora(inter['data_hora_entrada']), {'tipo': 'INTERNACAO', 'id_funcionario': inter['id_funcionario'],
                                                      'resumo': inter['motivo'],
                                                      'detalhes': {'id_internacao': inter['id_internacao'],
                                                                   'tipo': inter['tipo']}}))
        for o in ocupacoes.get(inter['id_internacao'], []):
            lt = leitos[o['id_leito']]
            ev.append((hora(o['data_hora_entrada']), {'tipo': 'OCUPACAO_LEITO', 'id_funcionario': None,
                                                      'resumo': f'Leito {lt["numero"]} - {locais[lt["id_local"]]["nome"]}',
                                                      'detalhes': {'id_ocupacao': o['id_ocupacao'], 'id_leito': lt['id_leito']}}))
        for tr in transferencias.get(inter['id_internacao'], []):
            ev.append((hora(tr['data_hora']), {'tipo': 'TRANSFERENCIA', 'id_funcionario': tr['id_funcionario'],
                                               'resumo': f'Transferência para {tr["destino"]}',
                                               'detalhes': {'id_transferencia': tr['id_transferencia'],
                                                            'tipo': tr['tipo']}}))
    for it in int_por_at.get(aid, []):
        ev.append((it['_momento'], {'tipo': 'INTERCORRENCIA', 'id_funcionario': it['responsavel']['id_funcionario'],
                                    'resumo': f'Intercorrência {it["categoria"].lower().replace("_", " ")} ({it["gravidade"].lower()})',
                                    'detalhes': {'codigo_intercorrencia': it['codigo_intercorrencia'],
                                                 'gravidade': it['gravidade']}}))
    a = altas.get(aid)
    if a:
        ev.append((hora(a['data_hora']), {'tipo': 'ALTA', 'id_funcionario': a['id_funcionario'],
                                          'resumo': f'{TIPO_ALTA[a["tipo"]]}' + (f' - CID {a["cid_final"]}' if a['cid_final'] else ''),
                                          'detalhes': {'id_alta': a['id_alta'], 'tipo_alta': a['tipo'],
                                                       'cid_final': a['cid_final']}}))
    ev.sort(key=lambda x: x[0])
    eventos = [{'tipo': e['tipo'], 'data_hora': data_mongo(t), 'id_funcionario': e['id_funcionario'],
                'resumo': e['resumo'], 'detalhes': e['detalhes']} for t, e in ev]
    linha_tempo.append({
        'id_atendimento': aid,
        'paciente_ref': paciente_ref(at, com_flag=False),
        'classificacao_risco': classif,
        'status_atual': status_at[at['id_status']]['descricao'],
        'queixa_principal': at['queixa_principal'],
        'local_atual': {'id_local': at['id_local'], 'nome': locais[at['id_local']]['nome'] if at['id_local'] else None},
        'data_hora_entrada': data_mongo(t0),
        'data_hora_encerramento': data_mongo(hora(a['data_hora'])) if a else None,
        'total_eventos': len(eventos),
        'eventos': eventos})


def limpar(doc):
    return {k: v for k, v in doc.items() if not k.startswith('_')}


ORDEM_INT = ['codigo_intercorrencia', 'id_atendimento', 'id_paciente', 'id_cadastro_provisorio', 'id_local', 'data_hora',
             'categoria', 'gravidade', 'status', 'descricao', 'responsavel', 'medidas_adotadas', 'data_hora_resolucao', 'tags']
intercorrencias_final = [{k: d[k] for k in ORDEM_INT} for d in intercorrencias]
colecoes = {
    'telemetria_sinais_vitais': [limpar(d) for d in telemetria],
    'logs_auditoria': logs,
    'intercorrencias_atendimento': intercorrencias_final,
    'linha_tempo_atendimento': linha_tempo,
}

PASTA_DATASETS.mkdir(parents=True, exist_ok=True)
PASTA_AMOSTRAS.mkdir(parents=True, exist_ok=True)
total = 0
for nome, docs in colecoes.items():
    with open(PASTA_DATASETS / f'{nome}.json', 'w', encoding='utf-8', newline='\n') as f:
        for d in docs:
            f.write(json.dumps(d, ensure_ascii=False, separators=(',', ':')) + '\n')
    amostra = docs[:: max(1, len(docs) // 30)][:30]
    if nome == 'telemetria_sinais_vitais':
        com_alerta = [d for d in docs if d['alertas_disparados']][:10]
        amostra = amostra[:20] + com_alerta
    with open(PASTA_AMOSTRAS / f'{nome}.json', 'w', encoding='utf-8', newline='\n') as f:
        json.dump(amostra, f, ensure_ascii=False, indent=2)
        f.write('\n')
    total += len(docs)
    print(f'{nome:30s} {len(docs):7d}')
print(f'{"TOTAL":30s} {total:7d}')
