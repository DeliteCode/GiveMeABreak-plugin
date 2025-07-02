#by DC 30/06/2025 

#ajuste as variaveis abaixo de acordo com o exemplo. O config de substituição deve estar na pasta do seu config atual carregado com o kore

#give_me_a_break 1 (ou 0)
#giveMeABreak_1_start 00:00
#giveMeABreak_1_end   02:30
#giveMeABreak_1_load  config_1.txt

#giveMeABreak_2_start 02:31
#giveMeABreak_2_end   04:00
#giveMeABreak_2_load  config_acc2.txt




package giveMeABreak;
use strict;
use Log qw/message/;
use Plugins;
use Commands;
use Globals qw/%config/;
use Settings;
use File::Basename;

my $HOOKS = Plugins::addHooks(
    ['in_game', \&check_and_swap_config],	
);

Plugins::register('giveMeABreak', 'Troca de config.txt por turnos automáticos, sem File::Copy', sub { Plugins::delHooks($HOOKS) });

sub check_and_swap_config {
    my (undef, $min, $hour) = localtime();
    my $now = $hour * 60 + $min;    

    # Verifica se o plugin está ativado via config
    unless (exists $config{give_me_a_break} && $config{give_me_a_break}) {
        message "giveMeABreak: DEBUG - Plugin desativado (give_me_a_break = 0)\n", "info";
        return;
    } else {
        message "giveMeABreak: DEBUG - Plugin ativado (give_me_a_break = 1)\n", "info";
    }

    # Monta hash de turnos configurados
    my %turnos;
    for my $key (keys %config) {
        if ($key =~ /^giveMeABreak_(\d+)_load$/) {
            $turnos{$1} = 1;
        }
    }
    unless (%turnos) {
        message "giveMeABreak: DEBUG - Nenhum turno configurado!\n", "info";
        return;
    }

    foreach my $i (sort { $a <=> $b } keys %turnos) {
        my $start  = $config{"giveMeABreak_${i}_start"};
        my $end    = $config{"giveMeABreak_${i}_end"};
        my $perfil = $config{"giveMeABreak_${i}_load"};
        unless ($start && $end && $perfil) {
            message "giveMeABreak: DEBUG - Turno $i incompleto (faltando start/end/load)\n", "info";
            next;
        }

        my ($start_h, $start_m) = split /:/, $start;
        my ($end_h,   $end_m)   = split /:/, $end;
        my $start_minutes = $start_h * 60 + $start_m;
        my $end_minutes   = $end_h   * 60 + $end_m;

        message "giveMeABreak: DEBUG - Agora: $hour:$min ($now min), Turno $i: $start ($start_minutes min) até $end ($end_minutes min)\n", "info";

        my $in_turn =
            ($start_minutes <= $end_minutes && $now >= $start_minutes && $now < $end_minutes)
            ||
            ($start_minutes > $end_minutes && ($now >= $start_minutes || $now < $end_minutes));

        if ($in_turn) {
            message "giveMeABreak: DEBUG - **Dentro do turno $i**\n", "info";

            my $main_cfg = Settings::getConfigFilename();
            message "giveMeABreak: DEBUG - main_cfg retornado: [$main_cfg]\n", "info";
            unless ($main_cfg) {
                message "giveMeABreak: [ERRO FATAL] main_cfg está vazio!\n", "system";
                return;
            }
            unless (-f $main_cfg) {
                message "giveMeABreak: [ERRO FATAL] main_cfg NÃO é arquivo: [$main_cfg]\n", "system";
                return;
            }

            message "giveMeABreak: Caminho do config principal (main_cfg): [$main_cfg]\n", "system";

            # Remove espaços do nome do perfil
            $perfil =~ s/^\s+|\s+$//g;
            message "giveMeABreak: Valor da variável perfil: [$perfil]\n", "system";

            my $config_dir = dirname($main_cfg);
            my $perfil_cfg = "$config_dir/$perfil";
            message "giveMeABreak: Hora atual $hour:$min. Turno $i, procurando config: [$perfil_cfg] (nome esperado: $perfil)\n", "system";

            unless ($perfil_cfg && -f $perfil_cfg) {
                message "giveMeABreak: [ERRO] Arquivo **NÃO ENCONTRADO** em: [$perfil_cfg] (nome original: $perfil)\n", "system";
                return;
            } else {
                message "giveMeABreak: Config encontrado em: $perfil_cfg\n", "system";
            }

            # Só troca se conteúdo diferente (evita relog loop)
            open my $main, '<', $main_cfg or do { message "ERRO ao abrir config principal $main_cfg: $!\n", "system"; return; };
            open my $perfil_fh, '<', $perfil_cfg or do { message "ERRO ao abrir config alvo $perfil_cfg: $!\n", "system"; return; };
            my $main_content   = join('', <$main>);
            my $perfil_content = join('', <$perfil_fh>);
            close $main; close $perfil_fh;
            if ($main_content eq $perfil_content) {
                message "giveMeABreak: Já está usando $perfil como config.txt\n", "system";
                last;
            }

            # Backup manual
            if (-f $main_cfg) {
                open my $src, '<', $main_cfg or do { message "Falha no backup: $!\n", "system"; return; };
                open my $dst, '>', $main_cfg.'.bak' or do { message "Falha no destino do backup: $!\n", "system"; close $src; return; };
                print $dst $_ while <$src>;
                close $src; close $dst;
                message "giveMeABreak: Backup de config.txt salvo.\n", "system";
            }

            # Sobrescreve config.txt
            open my $in,  '<', $perfil_cfg or do { message "ERRO ao abrir $perfil_cfg: $!\n", "system"; return; };
            open my $out, '>', $main_cfg   or do { message "ERRO ao escrever $main_cfg: $!\n", "system"; close $in; return; };
            print $out $_ while <$in>;
            close $in; close $out;

            message "giveMeABreak: Config.txt sobrescrito por $perfil. Dando reload+relog!\n", "system";
            Commands::run('reload config');
            Commands::run('relog 10');
            last;
        } else {
            message "giveMeABreak: DEBUG - Fora do turno $i\n", "info";
        }
    }
}

1;
